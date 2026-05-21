-- ============================================================================
-- File   : SQL script/fix_ss_RequestHttp_20260521.sql
-- Date   : 2026-05-21
-- Author : Antigravity
-- Mục đích: Sửa lỗi Msg 2786 trong procedure hệ thống ss_RequestHttp.
--           Thay đổi kiểu dữ liệu của @ErrSource từ INT thành VARCHAR(255)
--           để tránh type mismatch khi gọi sp_OAGetErrorInfo và định dạng %s trong RAISERROR.
-- ============================================================================

CREATE OR ALTER PROCEDURE [dbo].[ss_RequestHttp]
@Url varchar(1024), --
@ParamsValues varchar(max) =null, --
@Method varchar(10) ='Get', --
@data nvarchar(max) =null, --
@Accept varchar(256) =null, --
@ContentType varchar(256) =null, --
@Timeout float=null, -- in seconds
@AuthHeader varchar(256) =null, --
@AuthType varchar(256) =null, --
@UserName varchar(256) =null, --
@PassWord varchar(256) =null, --
@ProxyHostPort varchar(256) =null, --
@ProxyUserName varchar(256) =null, --
@ProxyPassWord varchar(256) =null, --
--
@envelope varchar(8000)=null,--
@UrlAction varchar(1024) =null,--
@SoapAction varchar(1024) =null,--
@SOAPActionRequestHeader varchar(1024) =null,\r\n--
@NoSelect int=null, --
@NoRaiseError bit=0, --
@Status int=null output, --
@StatusText varchar(256) =null output, --
@ResponseText nvarchar(max) =null output,--
--
@HeaderName1 nvarchar(255) =null, @HeaderName2 nvarchar(255) =null, @HeaderName3 nvarchar(255) =null, @HeaderName4 nvarchar(255) =null, @HeaderName5 nvarchar(255) =null, --
@Header1 nvarchar(max) =null, @Header2 nvarchar(max) =null, @Header3 nvarchar(max) =null, @Header4 nvarchar(max) =null, @Header5 nvarchar(max) =null
as
set nocount on
if @Method is null set @Method ='get'
if @Method ='get'and len(@ParamsValues)>0
set @Url=@Url+(case when @Url like '%?%' then '' else '?' end)+(case when @ParamsValues like '&%' then '' else '&' end)+@ParamsValues
declare
@ErrSource varchar(255), -- SỬA LỖI: Đổi từ INT thành VARCHAR(255) để tránh crash RAISERROR %s và sp_OAGetErrorInfo
@ErrDescription varchar(max),
@obj int,
@_Result int,
@responseXml xml,
@RetVal int=0,
@TimeoutMs int =@Timeout * 1000,
@_method varchar(10) =case when @Method ='soap' then 'POST' else @Method end
set @ContentType=case when @Method ='soap' then 'text/xml; charset=utf-8' else coalesce(@ContentType, case when @data is not null then 'application/json; charset=utf-8' end) end
set @SOAPActionRequestHeader = isnull(@SOAPActionRequestHeader,'')

begin try
	exec sp_OACreate 'MSXML2.ServerXMLHttp', @obj out
	exec @_Result=dbo.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj output
	if @_Result<>0 goto ok
	if @TimeoutMs is not null begin
		exec @_Result=dbo.sp_OAMethod @obj, 'SetTimeouts', null, 5000, 5000, @TimeoutMs, @TimeoutMs--- resolveTimeout, connectTimeout, sendTimeout, receiveTimeout
		if @_Result<>0 goto ok
	end
	if @Status is not null begin
		exec @_Result=dbo.sp_OAMethod @obj, 'SetOption', null, 2, 13056--- ignore server certificate errors
		if @_Result<>0 goto ok
	end
	exec @_Result=dbo.sp_OAMethod @obj, 'Open', null, @_method, @Url, 0 -- Async:=False
	if @_Result<>0 goto ok
	if @AuthHeader is null
	begin
		if @AuthType = 'Basic'
			set @AuthHeader = 'Basic '+dbo.fn_StringToBase64(@UserName+':'+@PassWord)
		--else if @AuthType = 'digest'
	end
	if @AuthHeader is not null begin
		exec @_Result=dbo.sp_OAMethod @obj, 'SetRequestHeader', null, 'Authorization', @AuthHeader
		if @_Result<>0 goto ok
	end
	if @ProxyUserName is not null and @ProxyPassWord is not null
	begin
		declare @ProxyAuthorization varchar(1024) = 'Basic '+dbo.fn_StringToBase64(@ProxyUserName+':'+@ProxyPassWord)
		exec @_Result=dbo.sp_OAMethod @obj, 'SetRequestHeader', null, 'Proxy-Authorization', @AuthHeader
	end
	if @Accept is not null begin
		exec @_Result=dbo.sp_OAMethod @obj, 'SetRequestHeader', null, 'Accept', @Accept
		if @_Result<>0 goto ok
	end
	if @ContentType is not null begin
		exec @_Result=dbo.sp_OAMethod @obj, 'SetRequestHeader', null, 'Content-Type', @ContentType
		if @_Result<>0 goto ok
	end
	if @HeaderName1 is not null begin
		exec @_Result=dbo.sp_OAMethod @obj, 'SetRequestHeader', null, @HeaderName1, @Header1
		if @_Result<>0 goto ok
	end
	if @HeaderName2 is not null begin
		exec @_Result=dbo.sp_OAMethod @obj, 'SetRequestHeader', null, @HeaderName2, @Header2
		if @_Result<>0 goto ok
	end
	if @HeaderName3 is not null begin
		exec @_Result=dbo.sp_OAMethod @obj, 'SetRequestHeader', null, @HeaderName3, @Header3
		if @_Result<>0 goto ok
	end
	if @HeaderName4 is not null begin
		exec @_Result=dbo.sp_OAMethod @obj, 'SetRequestHeader', null, @HeaderName4, @Header4
		if @_Result<>0 goto ok
	end
	if @HeaderName5 is not null begin
		exec @_Result=dbo.sp_OAMethod @obj, 'SetRequestHeader', null, @HeaderName5, @Header5
		if @_Result<>0 goto ok
	end
	if @_method in ('get', 'delete') begin
		exec @_Result=dbo.sp_OAMethod @obj, 'Send'
		if @_Result<>0 goto ok
	END
	else if @_method in ('post', 'put', 'patch') begin
		exec @_Result=dbo.sp_OAMethod @obj, 'Send', null, @data
		if @_Result<>0 goto ok
	end
	else if @_method = 'soap' begin
		declare @host varchar(1024) =@Url
		if @host like 'http://%' set @host=right(@host, len(@host)-7)else if @host like 'https://%' set @host=right(@host, len(@host)-8)
		if charindex(':', @host)>0 and charindex(':', @host)<charindex('/', @host)set @host=left(@host, charindex(':', @host)-1)else set @host=left(@host, charindex('/', @host)-1)
		if isnull(@envelope,'') =''
		begin
			if @SoapAction is null raiserror('@SoapAction is null', 10, 1)
			if @UrlAction is null set @UrlAction=@SOAPActionRequestHeader
			set @envelope ='<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">'
			+'<soap:Body><{action} xmlns=\"'+@UrlAction+'\">{params}{data}</{action}></soap:Body></soap:Envelope>'
			declare @params varchar(8000) =''
			while len(@ParamsValues)>0 begin
				declare @param varchar(256), @value varchar(256)
				if charindex('&', @ParamsValues)>0 begin
					set @param=left(@ParamsValues, charindex('&', @ParamsValues)-1)
					set @value=right(@param, len(@param)-charindex('=', @param))
					set @param=left(@param, charindex('=', @param)-1)
					set @params=@params+'<'+@param+'>'+@value+'</'+@param+'>'
					set @ParamsValues=right(@ParamsValues, len(@ParamsValues)-len(@param+'='+@value+'&'))
				end
				else begin
					set @value=right(@ParamsValues, len(@ParamsValues)-charindex('=', @ParamsValues))
					set @param=left(@ParamsValues, charindex('=', @ParamsValues)-1)
					set @params=@params+'<'+@param+'>'+@value+'</'+@param+'>'
					set @ParamsValues=null
				end
			end
			set @envelope=replace(@envelope, '{action}', isnull(@SoapAction,''))
			set @envelope=replace(@envelope, '{params}', isnull(@params,''))
			set @envelope=replace(@envelope, '{data}', isnull(@data,''))
		end
		print '@host: '+@host+' @SOAPActionRequestHeader: '+@SOAPActionRequestHeader+' @envelope: '+@envelope
		exec sp_OAMethod @obj, 'setRequestHeader', null, 'Host', @host
		if @SOAPActionRequestHeader != '' exec sp_OAMethod @obj, 'setRequestHeader', null, 'SOAPAction', @SOAPActionRequestHeader
		exec sp_OAMethod @obj, 'send', null, @envelope
	end

	exec @_Result=dbo.sp_OAGetProperty @obj, 'Status', @Status output
	if @_Result<>0 goto ok
	exec @_Result=dbo.sp_OAGetProperty @obj, 'StatusText', @StatusText output
	if @_Result<>0 goto ok
	declare @TmpGetProperty table(Value nvarchar(max)) insert  @TmpGetProperty exec @_Result=dbo.sp_OAGetProperty @obj, 'ResponseText'
	if @_Result<>0 goto ok
	select  top 1   @ResponseText=Value from    @TmpGetProperty
end try
begin catch
    select  @ErrSource=convert(varchar(50), error_line()), @ErrDescription=rtrim(replace(error_message(), char(13)+char(10), ' '))
    select  @RetVal=1, @StatusText=@ErrDescription
    if coalesce(@NoRaiseError, 0)=0
        raiserror('Error on line %s: %s', 16, 1, @ErrSource, @ErrDescription)
end catch
ok:
if @obj is not null begin
    exec dbo.sp_OADestroy @obj
    set @obj=null
end
if @_Result<>0 begin
    select  @RetVal=1, @StatusText=convert(varchar(50), convert(binary(4), @_Result), 1)
    if coalesce(@NoRaiseError, 0)=0 begin
		exec dbo.sp_OAGetErrorInfo @obj, @ErrSource output, @ErrDescription output
        select  @ErrDescription=rtrim(replace(@ErrDescription, char(13)+char(10), ' '))
        raiserror('Error in %s: %s (0x%08X)', 16, 1, @ErrSource, @ErrDescription, @_Result)
    end
end
if isnull(@NoSelect,0) = 0
return @RetVal
GO

PRINT '[OK] Created/Altered procedure dbo.ss_RequestHttp with fix for Msg 2786.';
GO
