      { ———————————————————————————————————————————————————————————————— }
      {                          UMBRA TIMER v1.2                        }
      { ________________________________________________________________ }
      {                                                                  }
      { Description:   Extended date-time processor                      }
      { Last Update:   5 Feb 2019                                        }
      { Creator:       umbrastellar@gmail.com                            }
      { ________________________________________________________________ }
      {                                                                  }
      { LICENSE:  MPL v1.1                                               }
      {                                                                  }
      { The contents of this file are used with permission, subject to   }
      { the Mozilla Public License Version 1.1 (the "License"); you may  }
      { not use this file except in compliance with the License. You may }
      { obtain a copy of the License at                                  }
      { http://www.mozilla.org/MPL/MPL-1.1.html                          }
      {                                                                  }
      { Software distributed under the License is distributed on an      }
      { "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or   }
      { implied. See the License for the specific language governing     }
      { rights and limitations under the License.                        }
      { ________________________________________________________________ }

unit umTimers;
interface
uses System.SysUtils, System.DateUtils, umStrings, vcl.Dialogs, System.Classes;

Type
  TumTimerStatus = (umtStarted, umtPaused);

  TUmIntervalBetween = object
    MilliSeconds,
    Seconds,
    Minutes,
    Hours,
    Days,
    Months,
    Years: Integer;

    MilliSecondsTM,
    SecondsTM,
    MinutesTM,
    HoursTM,
    DaysTM,
    MonthsTM,
    YearsTM: Integer;

    DatePart,
    TimePart: String;

    procedure CalcBetween(const ANow, AThen: TDateTime);
    function  CalcAsTimer(ADateFormat, ATimeFormat:string):string;
  end;

  TumTimer=class
    Status: TumTimerStatus;
  protected
  public
    IsNonStop: Boolean;
    AddingTimerMode: Byte;
    AddTimersToEnd: Boolean;
    TimeFormat: String;
    DateFormat: String;
    DateDevider: String[1];
    DateFormatOrder: Byte;

    NonstopInterval,
    SessionInterval,
    ProcessInterval,
    LifeInterval: TUmIntervalBetween;

    TimerList: TStringList;

    TimerSleepingStart,
    TimerSleepingStop,
    TimerNonstopStart: TDateTime;

    TimerStartTXT,
    TimerStopTXT,
    TimerProcessTXT,
    TimerSessionTXT,
    TimerNonstopTXT,
    TimerCreatedTXT,
    TimerProcessMilisecTXT: String;

    DateStartTXT,
    DateStopTXT,
    DateProcessTXT,
    DateSessionTXT,
    DateNonstopTXT,
    DateCreatedTXT: String;

    TimerStart,
    TimerStop,
    TimerNonstop,
    TimerSession,
    TimerProcess,
    TimerContinued,
    TimerNow,
    TimerCreated: TDateTime;

    constructor Create;
    destructor Destroy; override;

    procedure ProcessSession;
    Procedure ProcessNonstop;

    procedure Process;

    function TimerGetStop: String;

    procedure SetTimeFormat(AFormat:String);
    procedure SetDateFormat(AFormat:String);

    procedure LoadTimer(AText:String);
    procedure InitTimer(ATimerCreated, ATimerStart, ATimerStop: TDateTime; AStarted:Boolean);

    function  SaveTimer: string;
    
    function  GetDatePrefix(ATimer:TDateTime): String;
    function  GetCreatedDateTimeTXT(ADevider:string): String;
    function  GetStartedDateTimeTXT(ADevider:string): String;
    function  GetStoppedDateTimeTXT(ADevider:string): String;

    function  GetIntervalDatePrefix(AInterval:TUmIntervalBetween): String;

    procedure Pause;
    procedure PauseNonStop;
    function  Paused: boolean;

    procedure Continue;
    procedure Click;
    procedure TimerListInvert;
    procedure Clear;

    procedure Start;
    function Started: boolean;

    function GetProcessDurationStop:String;
    function GetProcessDurationNonStop:String;
  End;

  Function AddZeroes(Num:Integer; Count:Byte): String;

var
  umTimer: TumTimer;

implementation

// Создание таймера
constructor TumTimer.Create;
begin
  inherited Create;
  TimerCreated := 0;
  Status := umtPaused;
  SetTimeFormat('hh:nn:ss.zzz');
  SetDateFormat('mm\dd\yyyy');
  isNonStop := false;
  AddTimersToEnd:=true;
  TimerList := TStringList.Create;
  AddingTimerMode:=0;
end;

// Уничтожение таймера
destructor TumTimer.Destroy;
begin
  FreeAndNil(TimerList);
  inherited Destroy;
end;

// Быстрое определение длительности таймера с его остановкой
function TumTimer.GetProcessDurationStop:String;
begin
  Process;
  Pause;
  Result := TimerProcessTXT;
end;

// Быстрое определение длительности таймера без его остановки
function TumTimer.GetProcessDurationNonStop:String;
begin
  Process;
  Result := TimerProcessTXT;
end;

// Загрузка таймера
procedure TumTimer.LoadTimer(AText:String);
var
  DevidersCount: Byte;
  CreatedTM, StartTM, StopTM: TDateTime;
  isNonStop: Boolean;
  isStarted: Boolean;
  TimerParams: TnuSTR;
begin
  if (pos('=',AText)>0) then
  begin
    AText := trim(nuSTR.GetTextAfterText(AText,'=',AText));
  end;
  TimerParams := TnuSTR.create;
  TimerParams.PSTR := AText;
  TimerParams.setDevider('|');
  DevidersCount := AText.CountChar('|');

  TimerNow := UnivDateTime2LocalDateTime(DateTime2UnivDateTime(Now));

  if DevidersCount = 0 then
    TimerParams.PSTR := floattostr(TimerNow) + '|' + floattostr(TimerNow) + '|'
                      + floattostr(TimerNow) + '|' + floattostr(TimerNow) + '|'
                      + floattostr(TimerNow) + '';

  if DevidersCount = 1 then
    TimerParams.PSTR := TimerParams.PSTR + '|' + floattostr(TimerNow) + '|'
                      + floattostr(TimerNow)+'|'+floattostr(TimerNow);

  if DevidersCount = 2 then
    TimerParams.PSTR := TimerParams.PSTR+'|1|0';

  if DevidersCount = 3 then
    TimerParams.PSTR := TimerParams.PSTR+'|0';

  CreatedTM := TimerParams.CutFirstFloat;
  StartTM := TimerParams.CutFirstFloat;
  StopTM := TimerParams.CutFirstFloat;

  isNonStop := TimerParams.CutFirstInt.ToBoolean;
  isStarted := TimerParams.CutFirstInt.ToBoolean;
  freeandnil(TimerParams);

  InitTimer(CreatedTM, StartTM, StopTM, isStarted);
end;

// Инициализация таймера
procedure TumTimer.InitTimer(ATimerCreated, ATimerStart, ATimerStop: TDateTime; AStarted:Boolean);
begin
  IsNonStop := false;
  Pause;

  TimerNow := UnivDateTime2LocalDateTime(DateTime2UnivDateTime(Now));
  TimerCreated := ATimerCreated;
  TimerCreatedTXT:=FormatDateTime(TimeFormat,TimerCreated);
  DateCreatedTXT:=GetDatePrefix(TimerCreated);

  TimerStart := ATimerStart;
  TimerStop := ATimerStop;

  Continue;
  if not AStarted then Pause;
end;

// Сохранение таймера
function TumTimer.SaveTimer: string;
var
  oldStarted: Boolean;
begin
  oldStarted := Started;
  Pause;
  Result := floattostr(TimerCreated) + '|' + floattostr(TimerStart) + '|'
          + floattostr(TimerStop) + '|' + inttostr(isNonStop.ToInteger) + '|'
          + inttostr(oldStarted.ToInteger);

  if oldStarted then Status := umtStarted;
end;


// Установка и валидация формата времени
Procedure TumTimer.SetTimeFormat(AFormat:String);
begin
  if TimeFormat=AFormat then exit;
  AFormat := trim(lowercase(AFormat, loUserLocale));

  if (pos('.zz',AFormat)>0) and (pos('.zzz',AFormat) = 0) then
    AFormat := StringReplace(AFormat,'.zz','.zzz',[rfReplaceAll]);

  if (pos('.z',AFormat)>0) and (pos('.zzz',AFormat) = 0) then
    AFormat := StringReplace(AFormat,'.z','.zzz',[rfReplaceAll]);

  if (pos('s',AFormat)>0) and (pos('ss',AFormat) = 0) then
    AFormat := StringReplace(AFormat,'s','ss',[rfReplaceAll]);

  if (pos('n',AFormat)>0) and (pos('nn',AFormat) = 0) then
    AFormat := StringReplace(AFormat,'n','nn',[rfReplaceAll]);

  if (pos('h',AFormat)>0) and (pos('hh',AFormat) = 0) then
    AFormat := StringReplace(AFormat,'h','hh',[rfReplaceAll]);

  if (AFormat = 'hh:nn:ss.zzz') or
     (AFormat = 'nn:ss.zzz') or
     (AFormat = 'ss.zzz') or
     (AFormat = 'nn:ss') or
     (AFormat = 'ss') or
     (AFormat = 'hh:nn:ss') then TimeFormat := AFormat else TimeFormat := 'hh:nn:ss.zzz';

  TimerStartTXT := FormatDateTime(TimeFormat,TimerStart);
  TimerStopTXT := FormatDateTime(TimeFormat,TimerStop);
  TimerCreatedTXT := FormatDateTime(TimeFormat,TimerCreated);

  Process;
end;

// Установка и валидация формата даты
Procedure TumTimer.SetDateFormat(AFormat:String);
begin
  if DateFormat = AFormat then exit;
  AFormat := trim(lowercase(AFormat, loUserLocale));
  DateFormatOrder := 0;

  if AFormat='' then
  begin
    DateDevider := '';
  end else
  if pos('/',AFormat)>0 then
  begin
    DateDevider := '\';
    AFormat := stringreplace(AFormat,'/','\',[rfReplaceAll]);
  end else
  if pos('.',AFormat)>0 then
  begin
    DateDevider := '.';
  end else
  if pos('\',AFormat)>0 then
  begin
    DateDevider := '\';
  end;

  if AFormat<>'' then
  begin
    if AFormat[1] = 'd' then DateFormatOrder := 1 else
    if AFormat[1] = 'm' then DateFormatOrder := 2;
  end;

  if (AFormat = 'dddd d mmmm yyyy') or
     (AFormat = 'ddd d mmm yyyy') or
     (AFormat = 'mm.dd.yyyy') or
     (AFormat = 'mm\dd\yyyy') or
     (AFormat = 'dd.mm.yyyy') or
     (AFormat = 'dd\mm\yyyy') or
     (AFormat = '') then DateFormat := AFormat else DateFormat := 'dddd d mmmm yyyy';

  DateStartTXT := GetDatePrefix(TimerStart);
  DateStopTXT := GetDatePrefix(TimerStop);
  DateCreatedTXT := GetDatePrefix(TimerCreated);

  Process;
end;

// Вычисление интервала между таймерами
Procedure TUmIntervalBetween.CalcBetween(const ANow, AThen: TDateTime);
begin
  MilliSeconds := MilliSecondsBetween(ANow,AThen);
  Seconds := SecondsBetween(ANow,AThen);
  Minutes := MinutesBetween(ANow,AThen);
  Hours := HoursBetween(ANow,AThen);

  Days := DaysBetween(ANow,AThen);
  Years := YearsBetween(ANow,AThen);
  Months := MonthsBetween(ANow,AThen);

  MilliSecondsTM := MilliSeconds - Seconds * 1000;
  SecondsTM := Seconds - Minutes * 60;
  MinutesTM := Seconds div 60;
  HoursTM := Hours - Hours div 24;

  DaysTM := nuSTR.GetDaysBetweenDates(ANow,AThen);
  MonthsTM := Months - Years * 12;
  YearsTM := Years;
end;

// Перевод интервала между таймерами в формат секундомера
function TUmIntervalBetween.CalcAsTimer(ADateFormat, ATimeFormat:string):string;
begin
  TimePart := ATimeFormat;
  TimePart := stringReplace(TimePart,'zzz',AddZeroes(MilliSecondsTM,3),[rfReplaceAll,rfIgnoreCase]);
  TimePart := stringReplace(TimePart,'ss',AddZeroes(SecondsTM,2),[rfReplaceAll,rfIgnoreCase]);
  TimePart := stringReplace(TimePart,'nn',AddZeroes(MinutesTM,2),[rfReplaceAll,rfIgnoreCase]);
  TimePart := stringReplace(TimePart,'hh',AddZeroes(HoursTM,2),[rfReplaceAll,rfIgnoreCase]);

  DatePart := ADateFormat;
  DatePart := stringReplace(DatePart,'mmmm',AddZeroes(MonthsTM,2),[rfReplaceAll,rfIgnoreCase]);
  DatePart := stringReplace(DatePart,'mmm',AddZeroes(MonthsTM,2),[rfReplaceAll,rfIgnoreCase]);
  DatePart := stringReplace(DatePart,'mm',AddZeroes(MonthsTM,2),[rfReplaceAll,rfIgnoreCase]);

  DatePart := stringReplace(DatePart,'ddd',AddZeroes(DaysTM,2),[rfReplaceAll,rfIgnoreCase]);
  DatePart := stringReplace(DatePart,'dd',AddZeroes(DaysTM,2),[rfReplaceAll,rfIgnoreCase]);
  DatePart := stringReplace(DatePart,'d',AddZeroes(DaysTM,2),[rfReplaceAll,rfIgnoreCase]);

  DatePart := stringReplace(DatePart,'yyyy',AddZeroes(YearsTM,4),[rfReplaceAll,rfIgnoreCase]);
end;

// Возврат интервала между датами и временем
function TumTimer.GetIntervalDatePrefix(AInterval:TUmIntervalBetween): String;
begin
  AInterval.CalcAsTimer(DateFormat,TimeFormat);
end;

// Вовзрат даты создания таймера
function TumTimer.GetCreatedDateTimeTXT(ADevider:string): String;
begin
  Result := DateCreatedTXT;
  if Result<>'' then Result := Result + ADevider;
  Result := Result + TimerCreatedTXT;
end;

// Вовзрат даты запуска таймера
function TumTimer.GetStartedDateTimeTXT(ADevider:string): String;
begin
  Result := DateStartTXT;
  if Result<>'' then Result := Result + ADevider;
  Result := Result + TimerCreatedTXT;
end;

// Вовзрат даты остановки таймера
function TumTimer.GetStoppedDateTimeTXT(ADevider:string): String;
begin
  Result := DateStopTXT;
  if Result<>'' then Result := Result + ADevider;
  Result := Result + TimerCreatedTXT;
end;

// Процессинг таймера
procedure TumTimer.Process;
begin
  if Started then
  begin
    TimerNow := UnivDateTime2LocalDateTime(DateTime2UnivDateTime(Now));
    TimerProcess := TimerNow-TimerStart;
  end;

  ProcessInterval.CalcBetween(TimerNow,TimerStart);
  TimerProcessTXT := FormatDateTime(TimeFormat,TimerProcess);
  TimerProcessMilisecTXT := FormatDateTime('zzz',TimerProcess);
  DateProcessTXT := GetIntervalDatePrefix(ProcessInterval);

  ProcessSession;
  ProcessNonstop;
end;

// Процессинг нон-стоп таймера
Procedure TumTimer.ProcessNonstop;
begin
  TimerNonstop := TimerNow-TimerCreated;

  NonstopInterval.CalcBetween(TimerNow,TimerContinued);
  TimerNonstopTXT := FormatDateTime(TimeFormat,TimerNonstop);
  DateNonstopTXT := GetIntervalDatePrefix(NonstopInterval);
end;

// Процессинг микро-сессии между последней паузой и продолжением
Procedure TumTimer.ProcessSession;
begin
  TimerSession := TimerNow - TimerContinued;

  SessionInterval.CalcBetween(TimerNow,TimerContinued);
  TimerSessionTXT := FormatDateTime(TimeFormat,TimerSession);
  DateSessionTXT := GetIntervalDatePrefix(SessionInterval);
end;

// Фиксирование времени остановки
function TumTimer.TimerGetStop: String;
begin
  TimerStop := UnivDateTime2LocalDateTime(DateTime2UnivDateTime(Now));
  TimerStopTXT := FormatDateTime(TimeFormat,TimerStop);
  DateStopTXT := GetDatePrefix(TimerStop);

  result := TimerStopTXT;
  Process;
end;

// Получение префикса в ранее определённом формате даты и времени
function TumTimer.GetDatePrefix(ATimer:TDateTime): String;
var
  d,m,y: string;
begin
  if ATimer = 0 then
  begin
    d := '00';
    m := '00';
    y := '0000';
  end
  else begin
    d := FormatDateTime('dd',ATimer);
    m := FormatDateTime('mm',ATimer);
    y := FormatDateTime('yyyy',ATimer);
  end;

  if DateFormatOrder = 1 then Result := d + DateDevider + m + DateDevider + y else
  if DateFormatOrder = 2 then Result := m + DateDevider + d + DateDevider + y else Result := '';
end;

// Запуск таймера и фиксирование параметров
procedure TumTimer.Start;
begin
  Status := umtStarted;
  TimerNow := UnivDateTime2LocalDateTime(DateTime2UnivDateTime(Now));

  TimerCreated := TimerNow;
  TimerCreatedTXT := FormatDateTime(TimeFormat,TimerCreated);
  DateCreatedTXT := GetDatePrefix(TimerCreated);

  TimerStart := TimerNow;
  TimerStop := TimerStart;
  TimerContinued := TimerStart;

  TimerStartTXT := FormatDateTime(TimeFormat,TimerStart);
  DateStartTXT := GetDatePrefix(TimerStart);

  TimerStopTXT := FormatDateTime(TimeFormat,TimerStop);
  DateStopTXT := GetDatePrefix(TimerStop);

  Process;
end;

// Инвертирование финиш-листа (новые значения в конец или в начало)
procedure TumTimer.TimerListInvert;
var
  i: integer;
  tmpList: TStringList;
begin
  tmpList := TStringList.Create;

  for i := 0 to TimerList.Count-1 do tmpList.add(TimerList[TimerList.Count - i - 1]);

  TimerList.Text := tmpList.Text;
  FreeAndNil(tmpList);
end;

// Добавление нового значения в фини-лист
procedure TumTimer.Click;
var
  AddTimer: string;
  Postfix: string;
begin
  if TimerList.Count = 0
    then Postfix := FormatDateTime(TimeFormat,0)
    else Postfix := TimerSessionTXT;

  if AddingTimerMode = 0 then AddTimer := TimerProcessTXT else
  if AddingTimerMode = 1 then AddTimer := TimerProcessTXT + '    ( + ' + Postfix + ' )';

  if AddTimersToEnd
    then TimerList.Add('Finish   ░ ' + AddZeroes(TimerList.Count+1,2) +' ░    ' + AddTimer)
    else TimerList.Insert(0,'Finish   ░ ' + AddZeroes(TimerList.Count+1,2) +' ░    ' + AddTimer);

  TimerContinued := TimerNow;
  Process;
end;

// Очистка финищ-листа секундомера
procedure TumTimer.Clear;
begin
  TimerList.Clear;
end;

// Продолжение работы таймера
procedure TumTimer.Continue;
begin
  if Started then exit;

  Status := umtStarted;

  TimerNow := UnivDateTime2LocalDateTime(DateTime2UnivDateTime(Now));
  if not isNonStop  then
  begin
    TimerStart := TimerNow-(TimerStop-TimerStart);
  end;
  TimerContinued := TimerNow;

  TimerStartTXT := FormatDateTime(TimeFormat,TimerStart);
  DateStartTXT := GetDatePrefix(TimerStart);

  Process;
end;

// Приостановка таймера с заморозкой отсчёта
procedure TumTimer.Pause;
begin
  if not Started then exit;
  Status := umtPaused;
  if not isNonStop then TimerGetStop;
  Process;
end;

// Приостановка таймера без заморозки отсчёта
procedure TumTimer.PauseNonStop;
begin
  if not Started then exit;
  Status := umtPaused;
  Process;
end;

// Проверяем - приостановлен ли таймер
function TumTimer.Paused:boolean;
begin
  Result := status = umtPaused;
end;

// Проверяем - запущен ли таймер
function TumTimer.Started:boolean;
begin
  Result := status = umtStarted;
end;

// Добавление нулей при форматированном выводе таймера
Function AddZeroes(Num:Integer; Count:Byte): String;
Begin
  Result := IntToStr(Num);
  While Length(Result)<count Do Result := '0'+Result;
End;

initialization
  // Глобальный таймер для любых целей
  umTimer := TumTimer.Create;

finalization
  FreeAndNil(umTimer);
end.


