unit LazarusTelegramBot;


// Для использования этого модуля нужно установить
// indy10 (сетевой диспетчер пакетов),
// и подключить до проекта пакеты
// indylaz (инспектор проекта).


//{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IdHTTP, IdSSLOpenSSL, fpjson, jsonparser;


type

  { TTelegramBot }

  TTelegramBot=class(tobject)
    token: string;          //токен бота
    message_index:integer;
    idhttp: tidhttp;
    idssl: TIdSSLIOHandlerSocketOpenSSL;
    //json
    jData : TJSONData;      //джсон полученый при любом запросе
    jDataMessage:TJSONData; //джисон getUptdates
    jmessage : TJSONData;   //джсон сообщения

    //Функции DecodeUrl и EncodeUrl взял из сайта
    //https://forum.lazarus.freepascal.org/index.php?topic=15088.0
    function EncodeUrl(url: string): string;
    function DecodeUrl(url: string): string;
    //поиск сообщений
    function tryToGetAMessage:boolean;
    //получить значение
    function tryToGetValue(js:string):string;
    //отправка сообщений
    function sendMessage(chat_id,mes:string):boolean;
    function deleteMessage(chat_id,message_id:string):boolean;
    //используем особый метод
    function metod(met:string):boolean;
    //получить все сообщения
    function getUptdates(update_id:string):boolean;
    //отправить фото
    function sendPhoto(chat_id,photo:string):boolean;
    //отправить музыку
    function sendAudio(chat_id,audio:string):boolean;
    //отправить документ
    function sendDocument(chat_id,doc:string):boolean;
    //отправить видео
    function sendVideo(chat_id,video:string):boolean;
    //отправить анимацию   .gif
    function sendAnimation(chat_id,animation:string):boolean;
    //отправить .ogg
    function sendVoice(chat_id,Voice:string):boolean;
    //создать бота
    constructor Create;

  end;


type
  TTelegramBotConst=class(tobject)
   const
    update_id='update_id';
    message_message_id='message.message_id';
    message_from_first_name='message.from.first_name';
    message_from_last_name='message.from.last_name';
    message_from_username='message.from.username';
    message_from_language_code='message.from.language_code';

    message_chat_id='message.chat.id';
    message_chat_first_name='message.chat.first_name';
    message_chat_last_name='message.chat.last_name';
    message_chat_username='message.chat.username';
    message_chat_type='message.chat.type';

    message_text='message.text';
    message_date='message.date';

    message_sticker_width='message.sticker.width';
    message_sticker_height='message.sticker.height';
    message_sticker_emoji='message.sticker.emoji';
    message_sticker_set_name='message.sticker.set_name';
    message_sticker_is_animated='message.sticker.is_animated';
    message_sticker_thumb_file_id='message.sticker.thumb.file.id';
    message_sticker_thumb_file_file_unique_id='message.sticker.thumb.file.file_unique_id';
    message_sticker_thumb_file_file_size='message.sticker.thumb.file.file_size';
    message_sticker_thumb_file_width='message.sticker.thumb.file.width';
    message_sticker_thumb_file_height='message.sticker.thumb.file.height';
    message_sticker_file_id='message.sticker.file_id';
    message_sticker_file_unique_id='message.sticker.file_unique_id';
    message_sticker_file_size='message.sticker.file_size';

    message_animation_file_name='message.animation.file_name';
    message_animation_mime_type='message.animation.mime_type';
    message_animation_duration='message.animation.duration';
    message_animation_width='message.animation.width';
    message_animation_height='message.animation.height';
  end;

implementation


//Функции DecodeUrl и EncodeUrl взял из сайта
//https://forum.lazarus.freepascal.org/index.php?topic=15088.0
function TTelegramBot.EncodeUrl(url: string): string;
var
  x: integer;
  sBuff: string;
const
  SafeMask = ['A'..'Z', '0'..'9', 'a'..'z', '*', '@', '.', '_', '-'];
begin
  sBuff := '';
  for x := 1 to Length(url) do
  begin
    if url[x] in SafeMask then
    begin
      sBuff := sBuff + url[x];
    end
    else if url[x] = ' ' then
    begin
      sBuff := sBuff + '+';
    end
    else
    begin
      sBuff := sBuff + '%' + IntToHex(Ord(url[x]), 2);
    end;
  end;
  Result := sBuff;
end;

function TTelegramBot.DecodeUrl(url: string): string;
var
  x: integer;
  ch: string;
  sVal: string;
  Buff: string;
begin
  Buff := '';
  x := 1;
  while x <= Length(url) do
  begin
    ch := url[x];
    if ch = '+' then
    begin
      Buff := Buff + ' ';
    end
    else if ch <> '%' then
    begin
      Buff := Buff + ch;
    end
    else
    begin
      sVal := Copy(url, x + 1, 2);
      Buff := Buff + char(StrToInt('$' + sVal));
      Inc(x, 2);
    end;
    Inc(x);
  end;
  Result := Buff;
end;


{ TTelegramBot }


function TTelegramBot.tryToGetAMessage:boolean;
var s:string;
begin
 try
  s:='result['+inttostr(message_index)+']';
  jmessage:=getjson(jDataMessage.FindPath(s).AsJSON);
  inc(message_index);
  result:=true;
 except
  result:=false;
 end;
end;

function TTelegramBot.tryToGetValue(js: string): string;
begin
 try
 result:=jmessage.FindPath(js).AsString;
 except
 result:='';
 end;
end;


function TTelegramBot.sendMessage(chat_id, mes: string): boolean;
var s:string;
begin
  try
   if length(mes)>0 then
   begin
   s:='https://api.telegram.org/bot'+token+
   '/sendMessage?chat_id='+chat_id+'&text='+Encodeurl(mes);
   jdata:=getjson(idhttp.Get(s));
   result:=true;
   end else result:=false;
  except
   result:=false;
  end;
end;

function TTelegramBot.deleteMessage(chat_id, message_id: string): boolean;
var s:string;
begin
  try
   s:='https://api.telegram.org/bot'+token+
   '/deleteMessage?chat_id='+chat_id+'&message_id='+message_id;
   jdata:=getjson(idhttp.Get(s));
   result:=true;
  except
   result:=false;
  end;
end;

function TTelegramBot.metod(met: string): boolean;
var s:string;
begin
  try
   s:='https://api.telegram.org/bot'+token+'/'+EncodeUrl(met);
   jdata:=getjson(idhttp.Get(s));
   result:=true;
  except
   result:=false;
  end;
end;

function TTelegramBot.getUptdates(update_id:string): boolean;
var s,ui:string;
begin
if update_id<>'' then ui:='?offset='+update_id else ui:='';
  try
   s:='https://api.telegram.org/bot'+token+'/getUpdates'+ui;
   jDataMessage:=getjson(idhttp.Get(s));
   jdata:=getjson(jDataMessage.AsJSON);
   message_index:=0;
   result:=true;
  except
   result:=false;
  end;
end;

function TTelegramBot.sendPhoto(chat_id, photo: string): boolean;
var s:string;
begin
  try
   s:='https://api.telegram.org/bot'+token+
   '/sendPhoto?chat_id='+chat_id+'&photo='+photo;
   jdata:=getjson(idhttp.Get(s));
   result:=true;
  except
   result:=false;
  end;
end;

function TTelegramBot.sendAudio(chat_id, audio: string): boolean;
var s:string;
begin
  try
   s:='https://api.telegram.org/bot'+token+
   '/sendAudio?chat_id='+chat_id+'&audio='+audio;
   jdata:=getjson(idhttp.Get(s));
   result:=true;
  except
   result:=false;
  end;
end;

function TTelegramBot.sendDocument(chat_id, doc: string): boolean;
var s:string;
begin
  try
   s:='https://api.telegram.org/bot'+token+
   '/sendDocument?chat_id='+chat_id+'&document='+doc;
   jdata:=getjson(idhttp.Get(s));
   result:=true;
  except
   result:=false;
  end;
end;

function TTelegramBot.sendVideo(chat_id, video: string): boolean;
var s:string;
begin
  try
   s:='https://api.telegram.org/bot'+token+
   '/sendVideo?chat_id='+chat_id+'&video='+video;
   jdata:=getjson(idhttp.Get(s));
   result:=true;
  except
   result:=false;
  end;
end;

function TTelegramBot.sendAnimation(chat_id, animation: string): boolean;
var s:string;
begin
  try
   s:='https://api.telegram.org/bot'+token+
   '/sendAnimation?chat_id='+chat_id+'&animation='+animation;
   jdata:=getjson(idhttp.Get(s));
   result:=true;
  except
   result:=false;
  end;
end;

function TTelegramBot.sendVoice(chat_id, Voice: string): boolean;
var s:string;
begin
  try
   s:='https://api.telegram.org/bot'+token+
   '/sendVoice?chat_id='+chat_id+'&Voice='+Voice;
   jdata:=getjson(idhttp.Get(s));
   result:=true;
  except
   result:=false;
  end;
end;

constructor TTelegramBot.Create;
begin
  Inherited Create;
  //создаем объекты
  idhttp:=tidhttp.Create;
  idssl:= TIdSSLIOHandlerSocketOpenSSL.Create;
  //
  message_index:=0;
  //устанавливаем связь http&ssl
  idssl.SSLOptions.Method:=sslvSSLv23;
  idssl.SSLOptions.SSLVersions:=[sslvSSLv2,sslvSSLv3,sslvTLSv1,sslvTLSv1_1,sslvTLSv1_2];
  idhttp.IOHandler:=idssl;
end;

end.

