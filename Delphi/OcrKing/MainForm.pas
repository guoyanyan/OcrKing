unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdHTTP, StdCtrls, IdMultipartFormData, XMLDoc, XMLIntf,
  IdTCPConnection, IdTCPClient, IdBaseComponent, IdComponent, IdIOHandler,
  IdIOHandlerSocket, IdSSLOpenSSL;

const
  API_KEY='550f10baf8e9788e7frzMsMdDAm2xGvYJSYU8kVWF/Pac93CHyd1HrAR/aH7XzVcUCgfg2nkPX+eJFcw';//需要你申请一个apikey
  API_HOST='http://lab.ocrking.com/ok.html';//提交判断的主页
  CONST_VALID_IMAGE='https://www.bestpay.com.cn/api/captcha/getCode?1408294248050'; //获取验证码的页面

type
  //图片类型
  TOcrService=(osPassages,osPDF,osPhoneNumber,osPrice,osNumber,osCaptcha,osBarcode,osPDFImage);
  //语种
  TOcrLanguage=(olEng,olSim,olTra,olJpn,olKor);
  //字符集
  TOcrCharset=(ocEnglish,ocNumber,ocLowEnglish,ocUpEnglish,ocNumLowEng,ocNumUpEng
    ,ocAllEng,ocNumAllEng,ocEngChar,ocEmailWeb,ocShopPrice,ocPhoneNumber,ocFomula);
  TfrmMain = class(TForm)
    btn1: TButton;
    OD: TOpenDialog;
    cbbService: TComboBox;
    cbbLanguage: TComboBox;
    cbbCharset: TComboBox;
    mm: TMemo;
    btn2: TButton;
    idslhndlrsckt1: TIdSSLIOHandlerSocket;
    FHttp: TIdHTTP;
    procedure FormCreate(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
  private
    { Private declarations }
  public
    FAppPath:String;
  end;
  function OcrLanguage2Str(const AOcrCharset:TOcrLanguage):string;//语言枚举转字符串
  function OcrService2Str(const AService:TOcrService):string;//服务类型枚举转字符串
  function UrlEncode(const ASrc: string): string;//Url编码
var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

function UrlEncode(const ASrc: string): string;
const
  UnsafeChars = '*#%<>+ []';  //do not localize
var
  i: Integer;
begin
  Result := '';    //Do not Localize
  for i := 1 to Length(ASrc) do begin
    if (AnsiPos(ASrc[i], UnsafeChars) > 0) or (ASrc[i]< #32) or (ASrc[i] > #127) then begin
      Result := Result + '%' + IntToHex(Ord(ASrc[i]), 2);  //do not localize
    end else begin
      Result := Result + ASrc[i];
    end;
  end;
end;

function OcrLanguage2Str(const AOcrCharset:TOcrLanguage):string;
begin
  case AOcrCharset of
    olEng:Result:='eng';
    olSim:Result:='sim';
    olTra:Result:='tra';
    olJpn:Result:='jpn';
    olKor:Result:='kor';
  end;
end;

function OcrService2Str(const AService:TOcrService):string;
begin
  case AService of
    osPassages:Result:='OcrKingForPassages';
    osPDF:Result:='OcrKingForPDF';
    osPhoneNumber:Result:='OcrKingForPhoneNumber';
    osPrice:Result:='OcrKingForPrice';
    osNumber:Result:='OcrKingForNumber';
    osCaptcha:Result:='OcrKingForCaptcha';
    osBarcode:Result:='BarcodeDecode';
    osPDFImage:Result:='PDFToImage';
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FAppPath:=ExtractFilePath(Application.ExeName);
  if FAppPath[Length(FAppPath)]<>'\' then FAppPath:=FAppPath+'\';
end;

procedure TfrmMain.btn1Click(Sender: TObject);
var
  ms:TIdMultiPartFormDataStream;
  sAll,sUrl,sService,sLanguage,sCharset,sApiKey,sType,sResponse:String;
  xmlDocument:IXmlDocument;
  xmlNode:IXMLNode;
begin
  if OD.Execute then
    begin
      FHttp.Disconnect;
      mm.Clear;
      ms:=TIdMultiPartFormDataStream.Create;     
      try
        sUrl:='?url=';//如果是直接验证网络图片，则填写验证码生成地址
        sService:='&service='+OcrService2Str(TOcrService(cbbService.ItemIndex));//需要识别的类型
        sLanguage:='&language='+OcrLanguage2Str(TOcrLanguage(cbbLanguage.ItemIndex));//语种
        sCharset:='&charset='+IntToStr(cbbCharset.ItemIndex);//字符集
        sApiKey:='&apiKey='+API_KEY;//你申请的apikey
        sType:='&type='+CONST_VALID_IMAGE;//传递验证码原始产出地址
        sAll:=API_HOST+sUrl+sService+sLanguage+sCharset+sApiKey+sType;
        ms.AddFile('ocrfile',OD.FileName,'');//上传的文件，名称必须为ocrfile
        //如果你提交的参数有问题，可以尝试手动设置下面的值
        //FHttp.Request.ContentType:='multipart/form-data';
        //FHttp.Request.Host:='lab.ocrking.com';
        //FHttp.Request.Accept:='*/*';
        //FHttp.Request.ContentLength:=ms.Size;
        //FHttp.Request.Connection:='Keep-Alive';
        sResponse:=UTF8ToAnsi(FHttp.Post(sAll,ms));
        mm.Lines.Append(sResponse);
        xmlDocument:=LoadXMLData(sResponse);
        xmlNode:=xmlDocument.ChildNodes.FindNode('Results').ChildNodes.FindNode('ResultList').ChildNodes.FindNode('Item');
        mm.Lines.Add('状态:'+xmlNode.ChildNodes.FindNode('Status').NodeValue);
        mm.Lines.Add('结果:'+xmlNode.ChildNodes.FindNode('Result').NodeValue);
      finally
        ms.Free;
      end;
    end;
end;



procedure TfrmMain.btn2Click(Sender: TObject);
var
  ms:TMemoryStream;
begin
  ms:=TMemoryStream.Create;
  try
    FHttp.Disconnect;       
    FHttp.Get(CONST_VALID_IMAGE,ms);
    ms.SaveToFile(FAppPath+'yzm.png');
  finally
    ms.Free;
  end;
end;

end.
