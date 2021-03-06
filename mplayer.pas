unit mplayer;

interface
uses Windows, SysUtils, Classes, Forms, Graphics,StrUtils , NumUtils, FileUtils, mp3parser;

type TStatus=(sNone,sOpening,sClosing,sPlayStarting,sPlaying,sPaused,sStopped,sError,sErrorRetry);
type TNotifyEventLog = procedure(Sender: TObject; str:string) of object;
type TNOtifyEventOverlayChange = procedure(Sender : TObject;
                                required: boolean; color: Tcolor) of object;
type TNotifyEventStatusChange = procedure( Sender : TObject;
                                oldstatus : Tstatus;newstatus : TStatus) of object;
type TNotifyEventItemChange = procedure(sender : Tobject;
                                id : integer) of object;

type TNotifyEventProgress = procedure( Sender : TObject;
                                name: string; value : string) of object;
type TNotifyEventLoadNextFile = procedure (Sender : Tobject;
                                var name : string) of object;
type TNotifyEventFileLoaded = procedure (Sender : Tobject;
                                var name : string) of object;

    TStreamInfo=record
      Valid : boolean;
      FileName, FileFormat  :string;   //ici
      DurationString : string;
      HaveAudio, Havevideo : boolean;
      DurationMP : integer;
      DurationExt : integer;
      IsMp3 : boolean;

      IsDvdNav : boolean;
      IsDvd : boolean;
      Video:record
        Decoder, Codec, Fourcc: string;
        Bitrate, Width, Height: integer;
        FPS, Autoaspect: real;
        Interlaced : boolean;
      end;
      Audio:record
        Decoder, Codec: string;
        Bitrate, Rate, Channels: integer;
        VbrRate : integer;
      end;
      ClipInfo:array[0..9]of record
        Key, Value: string;
      end;
      stream: record
         start : int64;
         length : int64;
      end;
    end;

    TRenderInfo=record
      Width, Height : integer;
      //AudioId : integer;
      //SubID : integer;
      TitleID : integer;
      //ChapterID : integer;
      Aspect : real;
      VideoError : boolean;
      IsPlayingDVDMenu : boolean;
      HasVideoOverlay : boolean;
    end;

    TpropertyEntry = record
      name : string;    // property name
      min : integer;    // minimum value
      max : integer;    // max
      scale : Integer;  // scale factor for mplayer
      def : integer;   // default value, property value set to this when on Tmplayer.Create
                        // used too, to check if property has to be sended at start
                        // if it is <> 0, this property is set at start
    end;
    TpropertyValues = record
      default : integer;
      valid : boolean;
      Value : integer;
    end;

const
    SRC_FILE_DVDNAV = 'dvdnav://';
    SRC_FILE_DVD = 'dvd://';

    MAX_PROP_ENTRYS  = 5;
    MAX_CACHE_ENTRYS = 7;

    PROP_SUB_SCALE = 5;
    PROP_SUB_SCALE_LOADSUB_VALUE = 1.56;
    propertyEntrys : array[0..MAX_PROP_ENTRYS] of TpropertyEntry =(
         (name : 'brightness';min : -100; max : 100; scale : 0; def: 0),
         (name : 'contrast';min : -100; max : 100; scale : 0; def: 0),
         (name : 'saturation';min : -100; max : 100; scale : 0; def: 0),
         (name : 'hue';min : -100; max : 100; scale : 0; def: 0),
         (name : 'gamma' ;min : -100; max : 100; scale : 0; def: 0),
         (name : 'sub_scale' ;min: 1; max : 100; scale : 10; def: 30)
         );
    cacheEntrys : array[0..MAX_CACHE_ENTRYS] of string =(
                  'default','fixed','ramdisk','cdrom','removable','network','internet','dvd');


    CACHE_TYPE_DEFAULT = 0;
    CACHE_TYPE_FIXED = 1;
    CACHE_TYPE_RAMDISK = 2;
    CACHE_TYPE_CDROM  = 3;
    CACHE_TYPE_REMOVABLE = 4;
    CACHE_TYPE_NETWORK  = 5;
    CACHE_TYPE_INTERNET  = 6;
    CACHE_TYPE_DVD  = 7;

    IDS_TYPE_AUDIO = 1;
    IDS_TYPE_SUB = 2;
    IDS_TYPE_DVDTITLE =  10;
    IDS_TYPE_DVDCHAPTER = 20;

type


   TItemIdsEntry=class
    private
     Fid: integer;
     Fvalue :array[0..2] of integer;
     Ftext:string;
     Flang:string;
     function GetValue(Index: integer): integer;
    public
     property id : integer read Fid;
     property value[Index:integer]:integer read GetValue;
     property text : string read Ftext;
     property lang : string read Flang;
   end;


  TItemIds=class
   private
    FItems:array of TItemIdsEntry;
    Fselected : integer;
    FactualId : integer;
    FKind:integer;
    function GetCount:integer;
    function GetItem(Index:integer):TItemIdsEntry;
    procedure SetSelected(const Value:integer);
    function GetSelectedId: integer;
    procedure SetSelectedId(const Value: integer);
    function Add(id : integer; text  : string = ''; lang  : string = ''): integer;
    procedure Clear;
   protected
    //procedure SetItemLang(Index: integer; lang : string);
   public
    constructor Create(itemkind: integer);
    destructor Destroy(); override;
    function FindId(id: integer): integer;
    function ActualIndex() : integer;
    function ActualId(): integer;
    property Kind : integer read FKind;
    property Count:integer read GetCount;
    property Items[Index:integer]:TItemIdsEntry read GetItem;
    property Selected : integer read Fselected;
    property SelectedId : integer read GetSelectedId;
  end;

  Tmplayer = class

   private

    procedure SetDeinterlaceDVD(const Value: boolean);
    procedure SetUseDvdNav(const Value: boolean);
    procedure SetAVsyncPerFrame(const Value: integer);
    procedure SetAutosync(const Value: integer);

    {private classes}
    type TClientWaitThread=class(TThread)
      protected
        exitCode : DWORD;
        procedure Execute; override;
      public
        hProcess:Cardinal;
    end;
    type TNewDataProc = procedure(str:string) of object;
    type TProcessor=class(TThread)
      private
        Data:string;
        procedure Process;
      protected
        OnNewdata : TNewDataProc;
        procedure Execute; override;
      public
        hPipe:Cardinal;  //Thandle?
    end;
    {private types}
    type TMplayerProcess=record
      ClientWaitThread:TClientWaitThread;
      Processor:TProcessor;
      ClientProcess:Cardinal; //Thandle?
      ReadPipe,WritePipe:Thandle;
      FirstChance:boolean;
      ExplicitStop:boolean;
      LastLine:string;
      LineRepeatCount:integer;
      LastCacheFill :string;
    end;
    { Private declarations }

    //procedure sendAE(value: string);  //ici      audio equ
    procedure SendPropertyAE(Prop:string;value: string); //ici      audio equ
    procedure SendPropertyAE2(Prop:string;value: string); //ici      audio equ

    procedure SendCommand(Command:string);
    procedure SendProperty(Prop : string ; value : integer; silent : integer = 1);overload;
    procedure SendProperty(Prop : string ; value : real; silent : integer = 1);overload;
    procedure RequestProperty(Prop: string; get : boolean = true);

    procedure setAndSendProperty(prop : integer; value : integer; silent : integer = 1);

    function EscapeParam(const Param:string):string;
//    function UnEscapeParam(const Param:string):string; // check! if needed
    function isFileSeekable(vidfile : string) : boolean;
    function inVideoformat(str : string) : boolean;
    function isVideoformatMpg(): boolean;
    function isVideoformatMkv(): boolean;
    function isvideoformatLavf() : boolean;
    function isAudioSwitchNoRestart : boolean;

    function audio_stream_audio_format(fmt : string) : string;
    function audio_stream_mpg_format(id : integer): string;
    procedure SetCurrentAudioStreamFormat();

    procedure fixaspect(newaspect : real);

    function SplitLine(var Line:string):string;
    procedure ResetDefaultSettings;
    procedure ResetDefaultOptions;
    procedure ResetStreamInfo;
    procedure ResetIdsInfo;
    procedure ResetStatusInfo;
    function CreateCmdLine(const sFile: string; var CmdLine:string; wasInError : boolean ; check : boolean = false) : boolean;
    procedure Start(fromcue : boolean = false);
    procedure Restart(Reload : boolean = false);
    function StartNewDVDMedia(nexttitle : boolean = false) : boolean;

    procedure Terminate;
    procedure ClientDone(sender : TObject);

    function CalcSecondPosMp(value : integer) : integer;
    function CalcSecondPosExt(value : integer) : integer;

    procedure DoOnlog(str : string; fromMpui: boolean = true);
    procedure DoOnlogClear();
    procedure DoOnOverlayChange(required : boolean; color : Tcolor);
    procedure DoOnVideoSizeChanged;
    procedure DoOnPercentPosition(value : integer;forced : boolean = false);
    procedure DoOnSecondPosition(value : integer;forced : boolean = false);
    procedure DoOnAudioChange(id : integer);
    procedure DoOnSubChange(id : integer);
    procedure DoOnProgress(const name : string; const value : string);
    procedure DoOnsubAdded(id : integer);

    procedure LogInvalidPos(time : integer);
    procedure sendcmdsInit(cmdset : integer);
    procedure HandleInputLine(Line:string);
    procedure HandleIDLine(ID, Content: string);

    procedure sendSpeedCommand(Speed: real; silent: integer = 1);
    procedure SendVolumeCommand(Volume:integer; silent : integer = 1);
    procedure SendVolumeCommandSoftVol(Volume:integer; silent : integer = 1);
    procedure SendVolumeMuteCommand();
    procedure SendPauseCommand();
    procedure SendFrameStepCommand();
    procedure SendSeekcommand(value : int64; method : integer);
    procedure SendSeekIncCommand(Value : integer);
    procedure sendLoadFileCommand(const filename: string; inPlaylist : boolean = true);
    procedure sendLoadSubCommand(filename : string);
    procedure SendOsdShowCommand(const text : string; time: Integer);
    procedure SendQuitCommand();
    procedure SetAndSendAspectFactor(value : real = -1);
    procedure SetAndSendAspect(value : real);
    procedure SetAndSendAspectfromPreset(value : integer = -1);
    procedure getActualProperty(prop : integer);
    procedure getEqActualPropertys();
    procedure checksetEqPropertys();

    procedure SelectAudioTrack(id : integer);
    Procedure SelectSubTrack(id: integer; send : boolean = false);

    {----------------Private declarations propertys------------------}
    procedure CheckRestartNeeded(changes : boolean = true);
    procedure CheckRestartNeededByFonts();
    function GetRunning: boolean;

    procedure SetmplayerPath(const Value: string);
    procedure SetFileLoaded(const Value: string);

    procedure SetPriorityBoost(const Value: boolean);
    procedure SetReIndex(const Value: boolean);
    procedure SetParams(const Value: string);
    function GetCachesize(index: integer): integer;
    procedure SetCachesize(index: integer; const Value: integer);

    procedure SetFontEncoding(const Value: string);
    procedure SetFontPath(const Value: string);
    procedure SetSubAss(const Value: Boolean);
    procedure SetSubAutoLoad(const Value: Boolean);
    procedure SetFontConfig(const Value: Boolean);
    procedure SetSubAssBorderColor(const Value: tagRGBQUAD);
    procedure SetSubAssColor(const Value: tagRGBQUAD);
    procedure SetSubBgColor(const Value: tagRGBQUAD);

    function GetpropertyValues(index: integer): TPropertyValues;

    procedure Setoverlaycolor(const Value: Tcolor);
    procedure Setvideoout(const Value: string);
    procedure Setvideoeq(const Value: string);

    procedure SetDirectRender(const Value: boolean);
    procedure SetDoubleBuffer(const Value: boolean);
    procedure SetDrawSlices(const Value: boolean);

    procedure SetTryScaler(const Value: boolean);
    procedure SetVideoScaler(const Value: integer);

    procedure SetpostProc(const Value: integer);
    procedure SetDeinterlace(const Value: integer);
    procedure SetDeinterlaceAlg(const Value: integer);
    procedure SetAspect(const Value: integer);
    procedure SetAspectFactor(const Value: single);

    procedure SetAudioOut(const Value: integer);
    procedure SetAudioDev(const Value: integer);
    procedure SetAudioFilterChannels(const Value: string);

    procedure SetUseVolCmd(const Value: boolean);
    procedure SetSoftVol(const Value: boolean);
    procedure SetAudioDecodeChannels(const Value: integer);
    procedure SetAc3Comp(const Value: integer);
    procedure SetUseliba52(const Value: boolean);

    procedure SetSpeed(const Value : real);
    procedure SetVolume(const Value: integer);
    procedure SetMute(const Value: boolean);
    procedure SetPause(const Value: boolean);
    procedure SetOSDLevel(const Value: integer);

    function GetAudioID: integer;
    function GetSubID: integer;
    procedure SetAudioID(const Value: integer);
    procedure SetSubID(const Value: integer);
    procedure SetSubIDint(const Value : integer; fromprop: boolean = false);

    function GetTitleID: integer;
    function GetChapterID: integer;
    procedure SetTitleID(const Value: integer);
    procedure SetChapterID(const Value: integer);

    function GetValidFileInfo : Boolean;
    procedure SetStatus(const Value : Tstatus);
    procedure SetWindowHandle(const Value: cardinal);

    procedure SetOnlog(const Value: TNotifyEventLog);
    procedure SetOnlogClear(const Value: TNotifyEvent);
    procedure SetOnStatusChange(const Value : TNotifyEventStatusChange);
    procedure SetOnOverlayChange(const Value : TNOtifyEventOverlayChange);
    procedure SetOnProgress(const Value: TNotifyEventProgress);
    procedure SetOnAudioChange(const Value: TNotifyEventItemChange);
    procedure SetOnSubChange(const Value: TNotifyEventItemChange);
    procedure SetOnSubAdded(const Value :TNotifyEventItemChange);
    procedure SetOnPercentPosition(const Value: TNotifyEvent);
    procedure SetOnSecondPosition(const Value: TNotifyEvent);
    procedure SetOnVideoSizeChanged(const Value: TNotifyEvent);
    procedure SetOnPropertysRead(const Value : TNotifyEvent);
    procedure SetOnLoadNextFile(const Value: TNotifyEventLoadNextFile);
    procedure SetOnFileLoaded(const Value: TNotifyEventFileLoaded);


   const
    OSDFont : string ='Arial.ttf';
   var


    FMp3Info : TMp3Info;
    FRenderInfo : TRenderInfo;

    FmplayerPath : string;
    FMediaFile : string;

    FFontEncoding: string;
    FFontPath : string;
    FFontConfig : Boolean;
    FSubAss : Boolean;
    FSubAutoLoad : Boolean;
    FSubAssColor: tagRGBQUAD;
    FSubAssBorderColor: tagRGBQUAD;
    FSubBgColor: tagRGBQUAD;


    FPriorityBoost, FReIndex :boolean;
    FAutosync : integer;
    FAVsyncPerFrame : integer;
    FParams : string;
    FCachesize : array[0..MAX_CACHE_ENTRYS] of integer;

    aspectMsgOk : boolean;
    defaultreadini : integer;

    FpropertyValues : array[0..MAX_PROP_ENTRYS] of TPropertyValues;

    Foverlaycolor: Tcolor;
    Fvideoout: string;
    Fvideoeq: string;

    FDirectRender, FDoubleBuffer, FDrawSlices: boolean;

    FTryScaler: boolean;
    FVideoScaler: integer;
    FScalerTried: boolean;

    FpostProc : integer;
    FDeinterlace : integer;
    FDeinterlaceAlg : integer;
    FAspect : integer;
    FaspectFactor : single;

    FAudioOut, FAudioDev:integer;
    FAudioFilterChannels : string;

    FUseVolCmd, FSoftVol : boolean;
    FAudioDecodeChannels,FAc3Comp : integer;
    FUseliba52: boolean;



    FUseDvdNav : boolean;
    FDeinterlaceDVD : boolean;

    FSpeed : real;
    FVolume:integer;
    FMute:boolean;
    FOSDLevel:integer;
//    LastVolume:integer;

    FaudioIDs : TItemIds;
    FSubIDs : TItemIds;
    LastSelSubId : integer;
    FTitleIDs : TItemIds;
    FChapterIDs : TItemIds;
    FFileLoaded :string;
    FSubLoaded : string;


    Autoupdate : boolean;
    //Playbackstarted : boolean; ->should be in status
    cmdIniSent : integer;
    cmdIniRetry : integer;
    FirstOpen : boolean;
    CanceledOpen : boolean;
    FirstOpenCmd : string;
    RestartNeeded : boolean;
    RestartEnabled : boolean;
    DelayPositionQueries : integer;

    FStatus:TStatus;
    FPause : boolean;
    FIsOpening : boolean;
    FPercentPos:integer;
    FSecondPosMP:integer;
    FSecondPosExt : integer;
    FStreamPos : int64;
    FSecondPosInvalid : boolean;
    FUseSeekbystream : boolean;

    DidFramestep : boolean;

    ResumeSeek : integer;
    ResumeSeekPos : int64;
    ResumeseekSecond,ResumeseekSecondExt, ResumeseekPercent : integer;

    FWindowHandle : cardinal;

    FOnLog : TNotifyEventLog;
    FOnLogClear : TNotifyEvent;

    FOnStatusChange : TNotifyEventStatusChange;
    FOnOverlayChange : TNotifyEventOverlayChange;
    FOnSecondPosition: TNotifyEvent;
    FOnVideoSizeChanged: TNotifyEvent;
    FOnPercentPosition: TNotifyEvent;
    FOnAudioChange: TNotifyEventItemChange;
    FOnSubChange : TNotifyEventItemChange;
    FOnsubAdded : TNotifyEventItemChange;
    FOnProgress: TNotifyEventProgress;
    FOnPropertysRead : TNotifyEvent;
    FOnLoadNextFile: TNotifyEventLoadNextFile;
    FOnFileLoaded : TNotifyEventFileLoaded;
   protected
    PR : TMplayerProcess;
    FMplayerProcessId : DWORD;
    FMplayerThreadId : DWORD;
   public
    { Public declarations }
    //Streaminfo : TStreamInfo;
    Streaminfo: TstreamInfo;// read Streaminfo write Streaminfo;
    procedure sendAE(value: string);  //ici      audio equ
    procedure sendAE2(value: string);  //ici      audio equ

    function CheckIFContain(const Value, A:string): boolean;

    constructor Create();
    destructor Destroy(); override;

    procedure TimedTasks;
    procedure QueryPosition;

    procedure SendCmd(Command:string);
    procedure SetProperty(prop: integer; value : integer);
    function AspectpresetValue : real;

    function DeinterlaceCmd(Mode, Alg : integer; DeintDVD, IsDvd, Interlaced : boolean) : integer; overload;
    function DeinterlaceCmd(Mode, Alg : integer; DeintDVD: boolean) : integer; overload;
    function CacheSizeCmd(sFile: string): integer;

    function DVDgoMenu(): boolean;
    function DVDMenuClick() : boolean;
    function DVDMenuPostition(x : integer; y: integer) : boolean;

    procedure Playmedia(media : string);
    procedure Closemedia;
    function GetMplayerWindowHandle : HWnd;

    //procedure Pause;
    //procedure Unpause;
    procedure FrameStep;
    procedure SeekTo(value : int64; method : integer);
    procedure seekBy(Value : integer);
    procedure Stop;
    procedure StopAndWaitForDone;
    procedure ResumeplayStatus();
    procedure SendPlayPause();


    procedure StartPropertyChange();
    procedure EndPropertyChange();
    procedure ResetLogLastMsg();

    procedure LoadSubtitle(const filename : string);
    { Public declarations propertys}
    property Running : boolean read GetRunning;
    property MplayerProcessId : DWORD read FMplayerProcessId;
    property MplayerThreadId : DWORD read FMplayerThreadId;
    //property Streaminfo: TstreamInfo read Streaminfo write Streaminfo;
    property Mp3Info : TMp3Info read FMp3Info;
    property Renderinfo: TRenderInfo read FRenderinfo;

    property mplayerPath : string read FmplayerPath write SetmplayerPath;
    property MediaFile : string read FMediaFile;
    property FileLoaded : string read FFileLoaded write SetFileLoaded;

    property PriorityBoost : boolean read FPriorityBoost write SetPriorityBoost;
    property ReIndex : boolean read FReIndex write SetReIndex;

    property Autosync : integer read FAutosync write SetAutosync;
    property AVsyncPerFrame : integer read FAVsyncPerFrame write SetAVsyncPerFrame;

    property Params : string read FParams write SetParams;
    property Cachesize[index : integer]: integer read GetCachesize write SetCachesize;

    property FontEncoding : string read FFontEncoding write SetFontEncoding;
    property FontPath: string read FFontPath write SetFontPath;

    property FontConfig : Boolean read FFontConfig write SetFontConfig;
    property SubAss : Boolean read FSubAss write SetSubAss;
    property SubAutoLoad : Boolean read FSubAutoLoad write SetSubAutoLoad;
    property SubBgColor : tagRGBQUAD read FSubBgColor write SetSubBgColor;
    property SubAssBorderColor : tagRGBQUAD read FSubAssBorderColor write SetSubAssBorderColor;
    property SubAssColor : tagRGBQUAD read FSubAssColor write SetSubAssColor;

    property propertyValues[index: integer]: TPropertyValues read GetpropertyValues;

    property overlaycolor : Tcolor read Foverlaycolor write Setoverlaycolor;
    property videoout : string read Fvideoout write Setvideoout;
    property videoeq : string read Fvideoeq write Setvideoeq;

    property DirectRender : boolean read FDirectRender write SetDirectRender;
    property DoubleBuffer : boolean read FDoubleBuffer write SetDoubleBuffer;
    property DrawSlices : boolean read FDrawSlices write SetDrawSlices;

    property TryScaler : boolean read FTryScaler write SetTryScaler;
    property VideoScaler : integer read FVideoScaler write SetVideoScaler;
    property ScalerTried : boolean read FScalerTried;

    property postProc : integer read FpostProc write SetpostProc;
    property Deinterlace : integer read FDeinterlace write SetDeinterlace;
    property DeinterlaceAlg : integer read FDeinterlaceAlg write SetDeinterlaceAlg;
    property Aspect : integer read FAspect write SetAspect;
    property AspectFactor : single read FAspectFactor write SetAspectFactor;

    property AudioOut : integer read FAudioOut write SetAudioOut;
    property AudioDev : integer read FAudioDev write SetAudioDev;
    property AudioFilterChannels : string read FAudioFilterChannels write SetAudioFilterChannels;

    property UseVolCmd : boolean read FUseVolCmd write SetUseVolCmd;
    property SoftVol : boolean read FSoftVol write SetSoftVol;
    property AudioDecodeChannels : integer read FAudioDecodeChannels write SetAudioDecodeChannels;

    property Ac3Comp : integer read FAc3Comp write SetAc3Comp;
    property Useliba52 : boolean read FUseliba52 write SetUseliba52;

    property UseDvdNav : boolean read FUseDvdNav write SetUseDvdNav;
    property DeinterlaceDVD : boolean read FDeinterlaceDVD write SetDeinterlaceDVD;

    property Speed : real read FSpeed write SetSpeed;
    property Volume:integer read FVolume write SetVolume;
    property Mute:boolean read FMute write SetMute;
    Property Pause : boolean read FPause write SetPause;
    property OSDLevel:integer read FOSDLevel write SetOSDLevel;

    property AudioIDS : TitemIds read FAudioIds;
    property SubIDS : TitemIds read FSubIds;

    property AudioID : integer read GetAudioID write SetAudioID;
    property SubID : integer read GetSubID write SetSubID;

    property TitleIDS : TitemIds read FTitleIds;
    property ChapterIDS : TitemIds read FChapterIds;

    property TitleID : integer read GetTitleID write SetTitleID;
    property ChapterID : integer read GetChapterID write SetChapterID;

    property ValidFileInfo : Boolean  read GetValidFileInfo;
    property Status:TStatus read FStatus;
    property IsOpening:Boolean read FIsOpening;
    property PercentPos: integer read FPercentPos;
    property SecondPos:integer read FSecondPosExt;
    property StreamPos : int64 read FStreamPos;
    property SecondPosInvalid : boolean read FSecondPosInvalid;
    property UseSeekbystream : boolean read FUseSeekbystream;

    property WindowHandle : cardinal read FWindowHandle write SetWindowHandle;
    property ExplicitStop : boolean read pr.ExplicitStop;

    property Onlog : TNotifyEventLog read FOnlog write SetOnlog;
    property OnlogClear : TNotifyEvent read FOnlogClear write SetOnlogClear;

    property OnStatusChange : TNotifyEventStatusChange read FOnStatusChange write SetOnStatusChange;
    property OnOverlayChange : TNotifyEventOverlayChange read FOnOverlayChange write SetOnOverlayChange;
    property OnVideoSizeChanged : TNotifyEvent read FOnVideoSizeChanged write SetOnVideoSizeChanged;
    property OnPercentPosition : TNotifyEvent read FOnPercentPosition write SetOnPercentPosition;
    property OnSecondPosition : TNotifyEvent read FOnSecondPosition write SetOnSecondPosition;

    property OnAudioChange : TNotifyEventItemChange read FOnAudioChange write SetOnAudioChange;
    property OnSubChange : TNotifyEventItemChange read FOnSubChange write SetOnSubChange;
    property OnSubAdded : TNotifyEventItemChange read FOnsubAdded write SetOnSubAdded;
    property OnProgress : TNotifyEventProgress read FOnProgress write SetOnProgress;
    property OnPropertysRead : TNotifyEvent read FOnPropertysRead write SetOnPropertysRead;

    property OnLoadNextFile : TNotifyEventLoadNextFile read FOnLoadNextFile write SetOnLoadNextFile;
    property OnFileLoaded : TNotifyEventFileLoaded read FOnFileLoaded write SetOnFileLoaded;
  end;
var AppdataDir: String;    //rajoutt� par nico
    AppDir:string;
    MusicDir:string;
    TempDir:String;
    //ShotDir:string;
implementation

const
  STR_PROPERTY_FAILED : string = 'Failed to get value of property';

//ar AppdataDir,ShotDir: String;    //rajoutt� par nico

function isMpgInterlaced(const mpgfile : string ; var seqCount : integer) : boolean;
  const
   BUFLEN = 4096;
   MAXREAD = 2000000;
   SYNCLEN = 3;
  var
   myFile    : File;
   readArray : array[0..15] of byte;
   readByte   : byte;

   rBlock : array[0..BUFLEN-1] of byte;
   rBlockMax : integer;
   rMaxRead : integer;
   filelen : int64;

   nOk  : Integer;

   readCount : integer;
   bufferCount : integer;

   interlaced : boolean;
   intCount : integer;
   proCount : integer;
   PcExt , SeqExt : boolean;

begin
  nOk := 0;
  readCount := 0;
  interlaced := false;
  intCount := 0;
  proCount := 0;
  seqCount := 0;

  SeqExt := false; //not necessary but avoids warnings
  PcExt := false;  //idem

  AssignFile(myFile, mpgfile);
  FileMode := fmOpenRead or fmShareDenyNone;

  Try
   Reset(myFile,  1);

   Try
    filelen := getFilelen64(mpgfile);

    if filelen > MAXREAD then
      rMaxRead := MAXREAD
    else
      rmaxread := filelen;

    rblockMax := rMaxRead;

    if rblockMax > BUFLEN then
      rblockMax := BUFLEN;
    if rMaxRead > MAXREAD then
      rMaxRead  :=  MAXREAD;

    bufferCount := BUFLEN;

    //showmessage(inttostr(GetTickCount()- IniTickValue));
         //(not Eof(myFile)) and
     while (readCount < rMaxRead) and (seqCount < 6)  do begin

      if bufferCount >= BUFLEN  then begin
        BlockRead(myFile, rBlock, rBlockMax);
        bufferCount := 0;
      end;

      readByte :=  rBlock[bufferCount];
      readArray[nOk]:= readByte;
      inc(bufferCount);
      inc(readCount);

      if nOk >= SYNCLEN  then begin

        if nOk = SYNCLEN   then begin  //start code
          if readByte = $B5 then begin
            inc(nOk);
            SeqExt := false;
            PcExt := false;
          end else //not valid code
            nOk := 0; //restart sync

        end else if nOk = SYNCLEN + 1 then  begin     //byte 4
          //Sequence_Extension
          if (readByte and $10) > 0 then begin
            SeqExt := true;
            inc(nOk);
          //Picture_Coding_Extension
          end else if (readByte and $80) > 0 then begin
            PcExt := true;
            inc(nOk)
          end else
            nOk := 0; //restart sync

        end else begin     //byte 5 +

          if SeqExt then begin

            if nOk = 5 then begin
              if  (readByte and $08) = 0 then
                inc(intCount)
              else
                inc(proCount);

              nOk := 0; //restart sync
              inc(seqCount);
            end;
          end else if PcExt then begin

            if nOk = 8 then begin
              if  (readByte and $80) = 0 then
                inc(intCount)
              else
                inc(proCount);
              nOk := 0; //restart sync
              inc(seqCount);
            end;
          end else
            nOk := 0; //restart sync

          if nOk <> 0 then
            inc(nOk);
        end;

      end else begin

        if nOk < SYNCLEN -1 then begin
          if readByte = 0 then
            inc(nOk)
          else
            nOk := 0;
        end else begin
          if readByte = 1 then
            inc(nOk)
          else
            if readByte <> 0 then
              nOk := 0; //restart sync
        end;
      end;
     end;
   Except //try reading file
   end;

   CloseFile(myFile);
  Except //try open file
  End;

  if intCount > 0 then
    if intCount >= proCount then
      interlaced := true;

  result := interlaced;
end;
function isInfileext(const filename : string;const extensions : string) : boolean;
var
  ext : string;
begin
  ext := UpperCase(ExtractFileExtNoDot(filename));
  Result := ansiPos('|' + ext + '|', '|' + extensions + '|')>0
end;
function isVideofileMpg(const vidfile : string) : boolean;
begin
  Result := isInfileext(vidfile,'MPG|MPEG|MPV|VOB|M2V');
end;
function isVideofileTs(const vidfile : string) : boolean;
begin
  Result := isInfileext(vidfile,'TS');
end;
function isVideofileMpaudio(const vidfile : string) : boolean;
begin
  Result := isInfileext(vidfile,'MP1|MP2|MP3');
end;
function isVideofile3gp(const vidfile : string) : boolean;
begin
  Result := isInfileext(vidfile,'3GP');
end;

function isVideoFileInterlaced(const vidfile : string) : boolean;
var
  seq : integer;
begin
    result := false;
    if isMpgInterlaced(vidfile,seq) then
      if seq >= 2 then
        result := true;
end;
function isVideofileDVDnav(const sfile : string): boolean; begin
    Result := (AnsiPos(SRC_FILE_DVDNAV,sfile) > 0);
end;
function isVideofileDVD(const sfile : string): boolean; begin
  Result := (AnsiPos(SRC_FILE_DVD,sfile) > 0);
  if result = false then
    Result := isVideofileDVDnav(sfile);
end;
function isVideofileInDrive(const sfile : string): boolean; begin
  Result := copy(sfile,2,2) = ':\';
end;
function isVideofileInNetwork(const sfile : string): boolean; begin
  Result := copy(sfile,1,2) = '\\';
end;
function isVideofileInRemoteNetwork(const sfile: string): boolean; begin
  Result := ansipos('://',sFile) > 0;;
end;
function isVideofileTV(const sfile: string): boolean; begin
  Result := ansipos('tv://',sFile) = 1;;
end;


{ TItemIdsEntry }

function TItemIdsEntry.GetValue(Index: integer): integer;
begin
  Result := Fvalue[Index];
end;


{TItemIds}
function TItemIds.Add(id : integer; text  : string = ''; lang  : string = ''): integer;
var
  index : integer;
  i: integer;
begin
  index := Count;
  SetLength(FItems,index +1);
  Result := index;
  Fitems[index] := TitemIdsEntry.Create;
  FItems[index].Fid :=id;
  FItems[index].Ftext := text;
  FItems[index].Flang := lang;
  for i := 0 to length(FItems[index].Fvalue)-1 do
    FItems[index].Fvalue[i] := -1;
end;

procedure TItemIds.Clear;
var i: integer;
begin
  for i := 0 to length(FItems)-1 do
    freeandnil(FItems[i]);

  SetLength(FItems,0);
  Fselected := -1;
  FactualId := -1;
end;

constructor TItemIds.Create(itemkind: integer);
begin
  SetLength(FItems,0);
  Fkind := itemkind;
  Clear;
end;

destructor TItemIds.Destroy;
begin
  Clear;
  inherited;
end;

function TItemIds.FindId(id: integer): integer;
var i : integer;
begin
  for i := 0 to count -1 do begin
    if FItems[i].id = id then begin
      Result := i;
      exit;
    end;
  end;
  Result := -1;
end;


function TItemIds.GetCount: integer;
begin
  Result:=length(FItems);
end;

function TItemIds.GetItem(Index: integer): TItemIdsEntry;
begin
  if (Index<Low(FItems)) OR (Index>High(FItems))
    then raise ERangeError.Create('invalid item')
    else Result:=FItems[Index];
end;

function TItemIds.ActualId: integer;
begin
  if FactualId >= 0  then
    Result := FactualId
  else
    Result := SelectedId;
end;

function TItemIds.ActualIndex: integer;
begin
  Result := Findid(ActualId);
  if Result < 0 then
    Result := 0;
end;

procedure TItemIds.SetSelected(const Value: integer);
begin
  if (Value<Low(FItems)) OR (Value>High(FItems))
    then raise ERangeError.Create('invalid item')
    else Fselected:=Value;
end;

function TItemIds.GetSelectedId: integer;
begin
  if (Fselected<Low(FItems)) OR (FSelected>High(FItems))
    then Result := -1
    else Result:=Fitems[Fselected].id;
end;
procedure TItemIds.SetSelectedId(const Value: integer);
var i : integer;
begin
  for i := 0 to count -1 do begin
    if FItems[i].id = Value then begin
      Fselected := i;
      break;
    end;
  end;
end;


{ Tmplayer.TClientWaitThread }

procedure Tmplayer.ClientDone(sender : TObject);
//var WasExplicit:boolean;
begin
   //when this procedure gets executed, thread execute function is already ended
  //if assigned(pr.ClientWaitThread) then pr.ClientWaitThread.Terminate;
  //if Assigned(pr.Processor) then pr.Processor.Terminate;

  FMplayerThreadId := 0;
  FMplayerProcessId := 0;
  pr.ClientProcess:=0;
  CloseHandle(pr.ReadPipe); pr.ReadPipe:=0;
  CloseHandle(pr.WritePipe);pr.WritePipe:=0;

  if (Status=sOpening) then begin
    FirstOpen := true;
    Streaminfo.Valid := false;
  end else
    FirstOpen := false;

  if (pr.ClientWaitThread <> nil) then begin
    if (Fmediafile <> '') then begin
      if PR.ClientWaitThread.exitCode <> 0 then begin
        DoOnlog('Mplayer returned exit code: ' +
                 Format('%d (%.8x)',
                    [LongInt(PR.ClientWaitThread.exitCode), PR.ClientWaitThread.exitCode]
                  )
               );
      end;

      if ( (Status=sOpening) or
           (PR.ClientWaitThread.ExitCode<>0)
         ) and
         (not pr.ExplicitStop) then begin
        if renderinfo.VideoError and
           FTryScaler and (not FScalerTried) then begin
           setstatus(sErrorRetry);
           ReStart(true);
        end else begin
          setstatus(sError)
        end;
      end else begin
        if ExplicitStop then
          setstatus(sStopped)
        else
          if not StartNewDVDMedia(true) then
            setstatus(sStopped)
      end;
    end else begin
      setstatus(sNone);
    end;
  end else begin
    setstatus(sError);
  end;

  //WasExplicit:=ExplicitStop OR (Status=sError);

  //do this by sending a message to the main form
  (*
  if (Status = sError) and renderinfo.VideoError and
      FTryScaler and (not FScalerTried) then begin

  end else begin
    if not WasExplicit then
      //MainForm.NextFile(1,psPlayed)
    else
      //playlistform.checkEmptyPlaylist;
  end;
  *)
end;
procedure Tmplayer.TClientWaitThread.Execute;
begin
  WaitForSingleObject(hProcess,INFINITE);
  GetExitCodeProcess(hProcess,ExitCode);
  //Synchronize(ClientDone);  //handled by onterminate event
end;
{ Tmplayer.TProcessor }
procedure Tmplayer.TProcessor.Process;
var LastEOL,EOL,Len:integer;
begin
  Len:=length(Data);
  LastEOL:=0;
  for EOL:=1 to Len do
    if (EOL>LastEOL) AND ((Data[EOL]=#13) OR (Data[EOL]=#10)) then begin
      Onnewdata(Copy(Data,LastEOL+1,EOL-LastEOL-1));
      LastEOL:=EOL;
      if (LastEOL<Len) AND (Data[LastEOL+1]=#10) then inc(LastEOL);
    end;
  if LastEOL<>0 then Delete(Data,1,LastEOL);
end;
{procedure Tmplayer.TProcessor.Execute;
const BufSize=1024;
var Buffer:array[0..BufSize]of char;
    BytesRead:cardinal;AnsiBuf: AnsiString;
begin

  Data:='';
  repeat
    BytesRead:=0;
    AnsiBuf := String(Buffer) + #13#10;
    //if not ReadFile(hPipe,Buffer[0],BufSize,BytesRead,nil) then break;
    if not ReadFile(hPipe,AnsiBuf[1],Length(AnsiBuf),BytesRead,nil) then break;
    //Buffer[BytesRead]:=#0;
    //Data:=Data+Buffer;
    Data:=Data+AnsiBuf;
    Synchronize(Process);
  until BytesRead=0;
end;}
procedure Tmplayer.TProcessor.Execute;
const BufSize=1024;
var Buffer:array[0..BufSize]of ansichar;
    BytesRead:cardinal;AnsiBuf: AnsiString;
begin

  Data:='';
  repeat
    BytesRead:=0;
    if not ReadFile(hPipe,Buffer[0],BufSize,BytesRead,nil) then break;
    Buffer[BytesRead]:=#0;
    Data:=Data+Buffer;
    Synchronize(Process);
  until BytesRead=0;
end;
{procedure Tmplayer.SendCommand(Command: string);
var Dummy:cardinal; AnsiBuf: AnsiString;
begin
  if (pr.ClientProcess=0) OR (pr.WritePipe=0) then exit;
  //DoOnlog('Exec cmd : ' + command);
  Command:=Command+#10;
  AnsiBuf := String(Command) + #13#10;
  //WriteFile(pr.WritePipe,Command[1],length(Command),Dummy,nil);
  WriteFile(pr.WritePipe,AnsiBuf[1],length(AnsiBuf),Dummy,nil);
end;}
{procedure Tmplayer.SendCommand(Command: string);
var Dummy:cardinal; AnsiBuf: AnsiString;
begin
  if (pr.ClientProcess=0) OR (pr.WritePipe=0) then exit;
  //DoOnlog('Exec cmd : ' + command);
  Command:=Command+#10;
  AnsiBuf := String(Command) + #13#10;
  //WriteFile(pr.WritePipe,Command[1],length(Command),Dummy,nil);
  WriteFile(pr.WritePipe,AnsiBuf[1],length(AnsiBuf),Dummy,nil);
end;
}
procedure Tmplayer.SendCommand(Command: string);
var Dummy:cardinal; AnsiBuf: AnsiString;
begin
  if (pr.ClientProcess=0) OR (pr.WritePipe=0) then exit;
  //DoOnlog('Exec cmd : ' + command);
  //Command:=Command+#10;
  AnsiBuf := ansistring(Command) + #10;
  WriteFile(pr.WritePipe,AnsiBuf[1],length(AnsiBuf),Dummy,nil);
  //WriteFile(pr.WritePipe,AnsiBuf[1],length(AnsiBuf),Dummy,nil);
end;
{ Tmplayer }
constructor Tmplayer.Create;
begin
  inherited;
  Application.UpdateFormatSettings := false;
  FormatSettings.DecimalSeparator := '.';

  FaudioIDs := TItemIds.Create(IDS_TYPE_AUDIO);
  FSubIDs := TItemIds.Create(IDS_TYPE_SUB);
  FTitleIDs := TItemIds.Create(IDS_TYPE_DVDTITLE);
  FChapterIDs := TItemIds.Create(IDS_TYPE_DVDCHAPTER);

  ResetDefaultOptions;
  ResetDefaultSettings;
  ResetStreamInfo;
  ResetIdsInfo;
  ResetStatusInfo;
  CanceledOpen := false;
end;

destructor Tmplayer.Destroy;
begin
  StopAndWaitForDone;
  Freeandnil(FaudioIDS);
  Freeandnil(FSubIDS);
  Freeandnil(FTitleIDs);
  Freeandnil(FChapterIds);
  inherited;
end;
function Tmplayer.CalcSecondPosMp(value : integer) : integer;
begin
  if (Streaminfo.DurationMP <> Streaminfo.DurationExt) and
     (Streaminfo.DurationExt > 0) then
    Result := (value * Streaminfo.DurationMP + (Streaminfo.DurationExt shr 1))
               div Streaminfo.DurationExt
  else
    Result := value;
end;
function Tmplayer.CalcSecondPosExt(value : integer) : integer;
begin
  if (Streaminfo.DurationMP <> Streaminfo.DurationExt) and
     (Streaminfo.DurationMP > 0) then
    Result := (value * Streaminfo.DurationExt +(Streaminfo.DurationMP shr 1))
              div Streaminfo.DurationMP
  else
    Result := value;
end;
procedure Tmplayer.TimedTasks;
begin
  if status = SPlayStarting then
    if cmdIniSent = 2 then
      if cmdIniRetry > 2 then begin
        DoOnlog('Retrying initial commands');
        cmdIniSent := 1;
        sendcmdsInit(2);
      end else
        inc(cmdIniRetry);
  QueryPosition;
end;
procedure Tmplayer.QueryPosition;
begin

  if DelayPositionQueries = 0 then begin
    if ((status = Splaying) or ((status = sPaused) and DidFramestep)) and running then
      if (FSecondPosInvalid) or (Streaminfo.DurationMP = 0)  then begin
        if Streaminfo.stream.length <= 0 then
          RequestProperty('percent_pos' , false)
        else
          RequestProperty('stream_pos' , true);
        ResumeplayStatus;
      end else
        if not Autoupdate then begin
          RequestProperty('time_pos',false);
          ResumeplayStatus;
        end else begin
          if DidFramestep then begin
            // do one frame, time will be sent automatically
            // pause status will be kept, no need to call ResumeplayStatus
             sendFrameStepCommand;
          end;
        end;
      DidFramestep := false;
  end else begin
    if (DelayPositionQueries mod 4) =1 then begin
      if Fstatus = sPlaying then begin
       DoonSecondPosition(FSecondPosExt+1,true);
//       doonlog('autoupdate to ' + inttostr(FSecondPosExt+1));//-d-
       if Streaminfo.DurationExt > 0 then begin
        FPercentpos := (int64(FSecondPosExt*100000) + (Streaminfo.DurationExt shr 1)) div Streaminfo.DurationExt;
        DoOnPercentPosition(FpercentPos,true);
       end;
      end;
    end;
    Dec(DelayPositionQueries);
  end;
end;

procedure Tmplayer.SendCmd(Command: string);
begin
  sendCommand(command);
  ResumeplayStatus();
end;
procedure Tmplayer.SendProperty(Prop: string; value: integer; silent: integer);
begin
  if silent = 1 then
    SendCommand('set_property ' + Prop  + ' ' +  inttostr(value))
  else
    SendCommand(Prop  + ' ' +  inttostr(value) + ' 1' );

  ResumeplayStatus();
end;
//ici -af equalizer=0:0:0:0:0:0:0:0:0:0
function Tmplayer.CheckIFContain(const Value, A:string): boolean;
var
  aPos: integer;
begin
  Result := false;
  aPos := Pos(A, Value);
  if aPos > 0 then
  begin
       result:=true;

  end;
end;
//////////////////////////create the equalizer//////////////////////////////////
procedure Tmplayer.sendAE(value: string);  //create the equalizer
var
str1:string;
begin
str1:='equalizer='+value ;

  //if fstatus=splaying then
  //begin
    FParams:='-af '+str1;
    SendPropertyAE('af', str1);
    ResumeplayStatus();
  //end;
end;
procedure Tmplayer.SendPropertyAE(Prop:string;value: string);
begin

    SendCommand(Prop  + ' ' +  value + ' 1' );
  ResumeplayStatus();
end;

//////////////////////////update the equalizer with new values//////////////////
procedure Tmplayer.sendAE2(value: string);
var
str1:string;
begin
str1:='equalizer='+value ;

  if fstatus=splaying then
  begin
    FParams:='-af '+str1;
    SendPropertyAE('af_cmdline equalizer ', value);
    //ResumeplayStatus();
  end;
  //if checkifcontain(fparams,'-af equalizer=') then


end;
procedure Tmplayer.SendPropertyAE2(Prop:string;value: string);
begin

    SendCommand('set_property ' + Prop  + ' ' +  value)
  //ResumeplayStatus();
end;
/////////////////////////////////////////////////////////////////////////////

procedure Tmplayer.SendProperty(Prop: string; value: real; silent: integer);
begin
  if silent = 1 then
    SendCommand('set_property ' + Prop  + ' ' +  formatfloat('0.####',value))
  else
    SendCommand(Prop  + ' ' +  formatfloat('0.####',value) + ' 1' );

  ResumeplayStatus();
end;

procedure Tmplayer.RequestProperty(Prop: string; get : boolean = true);
begin
  if get then
    SendCommand('get_property ' + Prop)
  else
    SendCommand('get_' + Prop);
end;

procedure Tmplayer.sendSpeedCommand(Speed: real; silent: integer);
begin
  if silent = 1 then
    SendProperty('speed', Speed, silent)
  else
    SendCommand('speed_set'  + ' ' +  formatfloat('0.####',Speed));
  ResumeplayStatus();
end;
procedure Tmplayer.SendVolumeCommand(Volume: integer; silent: integer);
begin
  SendProperty('volume', Volume, silent);
end;
procedure Tmplayer.SendVolumeCommandSoftVol(Volume, silent: integer);
begin
  if FSoftVol then volume := volume div 10;
  SendVolumeCommand( Volume, silent);
end;

procedure Tmplayer.SendVolumeMuteCommand();
begin
  SendProperty('mute', 1, -1);
end;
procedure Tmplayer.SendPauseCommand();
begin
  SendCommand('pause');
end;
procedure Tmplayer.SendFrameStepCommand();
begin
  SendCommand('frame_step');
end;
procedure Tmplayer.SendSeekcommand(value : int64; method : integer);
begin
  if method > 2 then
    if method = 3 then
      SendCommand('set_property stream_pos '+IntToStr(value))
    else
      SendSeekIncCommand(value-FSecondPosMP)
  else
    SendCommand('seek '+IntToStr(value)+' '+ inttostr(method));
end;
procedure Tmplayer.SendSeekIncCommand(Value : integer);
var cmd : string;
begin
  cmd := 'seek ';
  if value > 0 then
    cmd := cmd + '+';
  SendCommand('seek '+IntToStr(value));
end;
procedure Tmplayer.sendLoadFileCommand(const filename: string; inPlaylist : boolean = true);
var scmd : string;
begin
  FFileLoaded := filename;
  scmd := EscapeParam(stringReplace(filename,'\','/',[rfReplaceAll]));
  scmd := 'loadfile ' + scmd;
  if inPlaylist then
    scmd := scmd + ' 1';
  SendCommand(scmd);
  doonlog('File loaded in mplayer: ' + filename)
end;
procedure Tmplayer.sendLoadSubCommand(filename : string);
begin
  FsubLoaded := filename;
  filename := stringReplace(filename,'\','/',[rfReplaceAll]);
  SendProperty(propertyEntrys[PROP_SUB_SCALE].name, PROP_SUB_SCALE_LOADSUB_VALUE ,1);
  SendCommand('sub_load ' + EscapeParam(filename));
end;

procedure Tmplayer.SendOsdShowCommand(const text : string; time: Integer);
begin
  SendCommand('osd_show_text ''' + text + ''' ' + IntToStr(time) );
end;
procedure Tmplayer.SendQuitCommand();
begin
  SendCommand('quit');
end;
function Tmplayer.AspectpresetValue() : real;
begin
    case FAspect of
      1:Result :=  4/3;
      2:Result :=  16/9;
      3:Result :=  2.35;
      else Result := Streaminfo.Video.Autoaspect;
    end;
end;
procedure Tmplayer.SetAndSendAspectFactor(value : real);
var strcmd : string;
begin
  if value > 0 then
    FaspectFactor := value;

  if Frenderinfo.Aspect> 0.01 then begin
    strcmd := 'switch_ratio '+ formatfloat('0.####',Frenderinfo.Aspect*FaspectFactor);
    sendCommand(strcmd);
    ResumeplayStatus();
    DoOnlog(strcmd);
  end;
end;
procedure Tmplayer.SetAndSendAspect(value : real);
begin
  if value> 0.01 then begin
    Frenderinfo.Aspect := value;
    aspectMsgOk := true;
    SetAndSendAspectFactor;
  end;
end;
procedure Tmplayer.SetAndSendAspectfromPreset(value : integer);
var aspectR: real;
begin
  if value > -1 then
    FAspect := value;

  aspectR := AspectpresetValue();
  if aspectR> 0.01 then begin
    SetAndSendAspect(aspectR);
  end;
end;
procedure Tmplayer.SetProperty(prop: integer; value : integer);
begin
  setAndSendProperty(prop, value, -1);
end;
procedure Tmplayer.setAndSendProperty(prop, value: integer; silent: integer);
var newvalue : real;
begin
  if value < propertyEntrys[prop].min   then
    value :=  propertyEntrys[prop].min;
  if value > propertyEntrys[prop].max   then
    value :=  propertyEntrys[prop].max;

  Fpropertyvalues[prop].Value  := value;

  if (defaultreadini = 0) and Fpropertyvalues[prop].valid then begin

    if propertyEntrys[prop].scale = 0 then begin
      value := value + Fpropertyvalues[prop].default;

      if value < propertyEntrys[prop].min then
        value := propertyEntrys[prop].min
      else if value > propertyEntrys[prop].max then
        value := propertyEntrys[prop].max;

      SendProperty(propertyEntrys[prop].name, value,silent);
    end else begin
      newvalue := value/propertyEntrys[prop].scale;
//      if prop = PROP_SUB_SCALE then
//        if FAssSubs then
//          newvalue := newvalue *1.52/3.5;
      SendProperty(propertyEntrys[prop].name, newvalue ,silent);
    end;


  end;

end;
procedure Tmplayer.getActualProperty(prop : integer);
begin
    RequestProperty(propertyEntrys[prop].name, true);
end;
procedure Tmplayer.getEqActualPropertys();
var i : integer;
begin
    for i := 0 to high(propertyEntrys) do begin
      getActualProperty(i);
    end;
end;

procedure Tmplayer.checksetEqPropertys();
var i: integer;
begin
  for i := 0 to high(propertyEntrys) do begin
    if (propertyEntrys[i].def <> FpropertyValues[i].value )
        or (propertyEntrys[i].def <> 0)  then
      setAndSendProperty(i,FpropertyValues[i].Value);
  end;
end;


function Tmplayer.EscapeParam(const Param:string):string;
begin
  if Pos(#32,Param)>0 then Result:=#34+Param+#34 else Result:=Param;
end;
(*function Tmplayer.UnEscapeParam(const Param:string):string;
begin
  if copy(Param,1,1) = #34 then
    result := copy(Param, 2,length(Param)-2)
  else
    result := Param;
end;*)
function Tmplayer.DeinterlaceCmd(Mode, Alg : integer; DeintDVD, IsDvd, Interlaced : boolean) : integer;
var interlacedfile : boolean;
begin
    interlacedfile := (DeintDVD and IsDvd) or Interlaced;
    if (Mode = 1 ) or ((Mode = 2 ) and interlacedfile ) then
      Result := Alg +1
    else
      Result := 0;
end;
function Tmplayer.DeinterlaceCmd(Mode, Alg : integer; DeintDVD: boolean) : integer;
begin
  result := DeinterlaceCmd(Mode, Alg, DeintDVD, Streaminfo.IsDvd, Streaminfo.Video.Interlaced);
end;
function Tmplayer.CacheSizeCmd(sFile: string): integer;
var    drivestring :array[0..3]of Char; cacheType : integer;
begin

  if (ANSIPOS('-nocache', Fparams) > 0) or isVideofileTV(sFile) then begin
    Result := 0;
    exit;
  end;

  cacheType := CACHE_TYPE_DEFAULT;
    //check drive type for selecting cache
  if isvideofileInDrive(sFile) or isvideoFileDVD(sFile) then begin
    drivestring :=  '@:\';
    drivestring[0] := sFile[1];
    case GetDriveType(drivestring) of
      DRIVE_NO_ROOT_DIR: //same cache as network
        cacheType := CACHE_TYPE_NETWORK;
      DRIVE_REMOVABLE:
        cacheType := CACHE_TYPE_REMOVABLE;
      DRIVE_FIXED:
        cacheType := CACHE_TYPE_FIXED;
      DRIVE_REMOTE:
        cacheType := CACHE_TYPE_NETWORK; //network
      DRIVE_CDROM:
        cacheType := CACHE_TYPE_CDROM;
      DRIVE_RAMDISK:
        cacheType := CACHE_TYPE_RAMDISK;
    end;

    if isvideoFileDVD(sFile) and (Fcachesize[CACHE_TYPE_DVD] >= 0) then
      if (Fcachesize[CACHE_TYPE_DVD] < Fcachesize[cacheType]) or (Fcachesize[cacheType] < 0)  then
        cacheType := CACHE_TYPE_DVD;

  end else begin
    if isVideoFileInNetwork(sFile) then
      cacheType := CACHE_TYPE_NETWORK //network
    else if isVideoFileInRemoteNetwork(sFile) then
      cacheType := CACHE_TYPE_INTERNET; //internet
  end;

  Result := Fcachesize[cacheType];
end;


function Tmplayer.isFileSeekable(vidfile : string) : boolean;
begin
  Result := not isInfileext(vidfile,'AC3|MPV');
end;

function Tmplayer.inVideoformat(str : string) : boolean;
begin
  result := ansipos(str,uppercase(Streaminfo.FileFormat))>0;
end;

function Tmplayer.isVideoformatMpg(): boolean;
begin
  result := false;
  if inVideoformat('MPEG')  then
    result := true
  else if inVideoformat('MPG')  then
    result := true;
end;
function TMplayer.isVideoformatMkv(): boolean;
begin
  result := inVideoformat('MATROSKA');
end;
function Tmplayer.isvideoformatLavf() : boolean;
begin
  result := false;
  if inVideoformat('LIBAV') then
    result := true
  else if inVideoformat('LAVF') then
    result := true;
end;
function Tmplayer.isAudioSwitchNoRestart : boolean;
begin
  Result := isVideoformatMpg or isVideoformatMkv;
end;

procedure Tmplayer.fixaspect(newaspect : real); begin
    with Streaminfo do begin
     if not aspectMsgOk then begin

      //calculate aspect if no valid aspect
      if (newaspect < 0.01) and (video.Height > 0) then
         Video.AutoAspect:=Video.Width /Video.Height
      else
         Video.AutoAspect:=newaspect;

      //if valid aspect or aspect is undefined validate aspect
      if (newaspect > 0.01) or (newaspect < -0.5) then begin
        aspectMsgOk := true;
        //setAspectFactor;
        (*set aspect if aspect not auto or aspectfactor not 1.
          set aspect too if file is mpg format, to force aspect,
          because it can change throught the file, if it's not forced *)
        if (aspect <> 0) or (aspectfactor <> 1) or isVideoformatMpg then
          SetAndSendAspectfromPreset()
        else
          Frenderinfo.Aspect := Video.AutoAspect;
      end;

      //InfoForm.UpdateInfo;
     end;
     //MainForm.UpdateZoomLabel;
    end;
end;

function Tmplayer.SplitLine(var Line:string):string;
var i:integer;
begin

  i:=Pos(#32,Line);
  if (length(Line)<72) OR (i<1) then begin
    Result:=Line;
    Line:='';
    exit;
  end;
  if(i>71) then begin
    Result:=Copy(Line,1,i-1);
    Delete(Line,1,i);
    exit;
  end;
  i:=72; while Line[i]<>#32 do dec(i);
  Result:=Copy(Line,1,i-1);
  Delete(Line,1,i);
end;

procedure Tmplayer.ResetDefaultSettings;
var i : Integer;
begin
  FAspectFactor := 1;
  FVolume := 100;
  FMute := false;
  FOSDLevel := 1;
  FSpeed := 1;

  for i := Low(FpropertyValues) to High(FpropertyValues) do begin
    FpropertyValues[i].Value := propertyEntrys[i].def;
  end;
end;
procedure Tmplayer.ResetDefaultOptions;
  var WinDir:array[0..MAX_PATH]of char;
begin
  FPriorityBoost := false;
  FAutosync := 10;
  FAVsyncPerFrame := 100;
  FReIndex := false;
  FParams := '';
  Foverlaycolor := $122131;
  Fvideoout := 'direct3d';
  Fvideoeq := 'eq2,hue';
  FDirectRender := true;
  FDoubleBuffer := true;
  FDrawSlices := true;
  FTryScaler := true;
  FVideoScaler := 0;
  FpostProc := 0;
  FDeinterlace := 2; //auto
  FDeinterlaceAlg := 0;
  FAspect := 0; //auto
  FAudioOut := 3;
  FAudioDev := 0;
  FAudioFilterChannels := '';
  FUseVolCmd := false;
  FSoftVol := false;
  FAudioDecodeChannels := 6;
  Ac3Comp := 0;
  FUseliba52 := false;

  Fcachesize[CACHE_TYPE_DEFAULT] :=  3000;
  Fcachesize[CACHE_TYPE_FIXED] :=  -1;
  Fcachesize[CACHE_TYPE_RAMDISK] :=  -1;
  Fcachesize[CACHE_TYPE_CDROM] :=  3000;
  Fcachesize[CACHE_TYPE_REMOVABLE] :=  3000;
  Fcachesize[CACHE_TYPE_NETWORK] :=  3000;
  Fcachesize[CACHE_TYPE_INTERNET] :=  500;
  Fcachesize[CACHE_TYPE_DVD] :=  -1;

  FUseDvdNav := false;
  FDeinterlaceDVD := true;

  //default font path
  GetEnvironmentVariable('windir',@WinDir[0],MAX_PATH);
  FFontEncoding:='';
  //FFontPath:=IncludeTrailingPathDelimiter(WinDir)+'Fonts\'+OSDFont;
  //if not FileExists(FFontPath) then
    FFontPath := 'Arial';
  //default mplayer path
  Fmplayerpath:=IncludeTrailingPathDelimiter(ExtractFileDir(ExpandFileName(ParamStr(0))));
  FSubAss := False;
  FFontConfig := False;
  FSubAutoLoad := True;

  with FSubAssColor do begin
    rgbRed := 255;
    rgbGreen := 255;
    rgbBlue := 255;
    rgbReserved := 255;
  end;
  with FSubAssBorderColor do begin
    rgbRed := 0;
    rgbGreen := 0;
    rgbBlue := 0;
    rgbReserved := 255;
  end;
  with FSubBgColor do begin
    rgbRed := 0;
    rgbGreen := 0;
    rgbBlue := 0;
    rgbReserved := 0;
  end;
end;

procedure Tmplayer.ResetIdsInfo;
begin
  FaudioIDs.Clear;
  FsubIds.Clear;
  FTitleIDs.Clear;
  FChapterIDs.Clear;
  //Frenderinfo.AudioId := -1;
  //Frenderinfo.SubID := -1;
  FSubLoaded := '';
  FFileLoaded := '';
  LastSelSubId := -1;
  //update mainform menus
end;
procedure Tmplayer.ResetStatusInfo;
begin
  defaultreadini := high(FpropertyValues) +1;
  with FRenderInfo do begin
    Width := 0;
    Height := 0;
    AudioId := -1;
    Audioids.FactualId := -1;
    SubId := -1;
    SubIds.FactualId := -1;
    TitleID := -1;
    TitleIds.FactualId := -1;
    ChapterID := -1;
    ChapterIds.FactualId := -1;
    Aspect := 0;
    VideoError := false;
    IsPlayingDVDMenu := false;
    HasVideoOverlay := false;
  end;
  FPercentPos:=0;
  FSecondPosMP:=-1;
  FSecondPosExt := -1;
  FSecondPosInvalid := false;
  FUseSeekbystream := false;
  FStreampos := -1;
  pr.ExplicitStop:=false;
  cmdIniSent := 0;
  cmdIniRetry := 0;
  DelayPositionQueries := 0;

  RestartNeeded := false;
  RestartEnabled := true;
  DidFramestep := false;
end;

procedure Tmplayer.ResetStreamInfo;
var i:integer;
begin

 with Streaminfo do begin
  Valid := false;
  FileName:='';
  FileFormat:='';
  Haveaudio := true;
  HaveVideo := true;
  Durationstring := '';
  DurationMP := 0;
  DurationExt := 0;

  IsMp3 := false;
  IsDvdNav := false;
  IsDvd := false;

  aspectMsgOk := false;
  with Video do begin
    Decoder:=''; Codec:=''; Fourcc:='';
    Bitrate:=0; Width:=0; Height:=0; FPS:=0.0; Autoaspect := 0.0;
    Interlaced := false;
  end;
  with Audio do begin
    Decoder:=''; Codec:='';
    Bitrate:=0; Rate:=0; Channels:=0;
  end;
  with stream do begin
    stream.start := -1;
    stream.length := 0;
  end;
  for i:=0 to 9 do
    with ClipInfo[i] do begin
      Key:=''; Value:='';
    end;
 end;
end;

function Tmplayer.CreateCmdLine(const sFile: string; var CmdLine:string; wasInError : boolean ; check : boolean = false) : boolean;
  function TColorToHexBGR( Color : TColor ) : string;
  begin
    Result :=
      IntToHex( GetBValue( Color ), 2 ) +
      IntToHex( GetGValue( Color ), 2 ) +
      IntToHex( GetRValue( Color ), 2 ) ;
  end;
  function RGBAToHexRGBAInv(color : TRGBQuad) : string;
  begin
    Result :=
      IntToHex(color.rgbRed   , 2 ) +
      IntToHex(Color.rgbGreen , 2 ) +
      IntToHex(Color.rgbBlue  , 2 ) +
      IntToHex( 255 - Color.rgbReserved  , 2 ) ;
  end;
var
  IsDvd : boolean;
  IsDvdNav : boolean;
  fileLength : int64;
  Interlaced : boolean;
  HasVideoOverlay : boolean;
  cachesize : integer;
  scaler : boolean;


  sVideoOut : string;
  sColorkey : string;
  colorValue : Integer;
begin

  IsDvd := isVideofileDVD(sFile);
  IsDvdNav := isVideofileDVDnav(sFile);

  interlaced := false;
  fileLength := 0;
  if not IsDvd then begin // check if file, not dvd
    filelength := getFilelen64(sFile);
    if isVideofileMpg(sFile) or isVideofileTs(sFile) then begin
      if not check then
        DoOnLog('Testing for interlaced:');
      Interlaced := isVideoFileInterlaced(sFile);
    end;
  end;

  if not check then begin
    if not IsDvd then
      if Interlaced then
        DoOnLog('Interlaced file detected')
      else
        DoOnLog('Progressive file detected')
    else
      DoOnLog('Dvd file, interlacing unknown');
    DoOnLog('');

    if isVideofileMpaudio(sFile) then begin
      Streaminfo.IsMp3 := GetMp3Info(sFile,FMp3Info);
      if (Streaminfo.IsMp3) and (fmp3info.Duration > 0) then begin
        Streaminfo.DurationExt := fmp3info.Duration;
      end;
      if Fmp3info.VbrBitRate > 0 then
        DoOnLog('Mp3 Vbr file detected');
    end;
  end;

  // -VO AND OVERLAY
  HasVideoOverlay := true;
  if FvideoOut = '' then
    sVideoOut := ''
  else begin
    sVideoOut := ' -vo ' + FvideoOut;
    if  AnsiPos('directx', sVideoOut) = 0 then
      HasVideoOverlay := false
  end;

  if HasVideoOverlay then begin
    if not check then
      DoOnOverlayChange(true, Foverlaycolor);
    sColorkey := ' -colorkey 0x' + TColorToHexBGR(Foverlaycolor);
  end else begin
    if not check then
      DoOnOVerlayChange(false, clblack);
    sColorkey := '';
  end;

  // MPLAYER AND ESSENTIAL PARAMETERS
  CmdLine:=EscapeParam(FMplayerpath+'mplayer.exe')+' -slave -identify';

  CmdLine := CmdLine +' -wid '+IntToStr(FWindowHandle)
            //+ ' -ass '
            + sColorkey + sVideoOut;
  // OTHER PARAMENTERS
  if FPriorityBoost then CmdLine:=CmdLine+' -priority abovenormal';
  // VIDEO PARAMETERS
  if FDirectRender  then
    CmdLine := CmdLine + ' -dr';
  if not DoubleBuffer  then
    CmdLine := CmdLine + ' -nodouble';
  if not DrawSlices  then
    CmdLine := CmdLine + ' -noslices';

  CmdLine := CmdLine +' -nokeepaspect -framedrop';
  // AV-SYNC PARAMS
  if FAutosync > 0 then
    cmdLine := CmdLine + ' -autosync ' + inttostr(FAutosync);
  if FAVsyncPerFrame > 0 then
    cmdLine := CmdLine + ' -mc ' + formatfloat('0.####',FAVsyncPerFrame/1000000);
  if FReIndex then CmdLine:=CmdLine+' -idx';

  // OSD-SUB PARAMS
  if fFontPath <> '' then
    CmdLine := CmdLine + ' -font ' + escapeparam(fFontPath);
  if fFontEncoding <> '' then
    CmdLine := CmdLine + ' -subcp ' + escapeparam(fFontEncoding);
  if not FFontConfig then
    CmdLine := CmdLine + ' -nofontconfig';
  if FSubAss then begin
    CmdLine := CmdLine + ' -ass';
    CmdLine := CmdLine + ' -ass-color ' + RGBAToHexRGBAInv(FSubAssColor);
    CmdLine := CmdLine + ' -ass-border-color ' + RGBAToHexRGBAInv(FSubAssBorderColor);
  end;

  CmdLine := CmdLine + ' -sub-bg-color ' + IntToStr(FSubBgColor.rgbRed);

  if SubBgColor.rgbReserved = 0 then
    colorValue := 0
  else
    colorValue := 256 - FSubBgColor.rgbReserved;
  CmdLine := CmdLine + ' -sub-bg-alpha ' + IntToStr(colorValue);

  if not FSubAutoLoad then
    CmdLine := CmdLine + ' -noautosub';


  CmdLine := CmdLine + ' -subfont-text-scale ' +
                        formatfloat('0.####',PROP_SUB_SCALE_LOADSUB_VALUE);

  // AUDIO PARAMS
  if FSoftVol then CmdLine:=CmdLine+' -softvol -softvol-max 1000';
  if FUseVolCmd then
    CmdLine := Cmdline + ' -volume 0';

  // -AO PARAMETERS AND SELECTED AUDIO
  case FAudioOut of
    0:CmdLine:=CmdLine+' -nosound';
    1:CmdLine:=CmdLine+' -ao null';
    2:CmdLine:=CmdLine+' -ao win32';
    3:CmdLine:=CmdLine+' -ao dsound:device='+IntToStr(FAudioDev);
  end;
  if (not check) and (FAudioIDs.SelectedId>=0) AND (FAudioOut>0) then
    CmdLine:=CmdLine+' -aid '+IntToStr(FAudioIDs.SelectedId);
  // AUDIO CHANNEL DECODING
  if FAudioDecodeChannels >= 0 then
    CmdLine := Cmdline + ' -channels ' + inttostr(FAudioDecodeChannels);
  // AC3 COMPRESSION
  if FUseliba52 then
    CmdLine := Cmdline + ' -a52drc ' + floattostr(FAc3Comp/100);
  // SUBTITLES
  //if FSubIDs.SelectedId >=0 then
  //  CmdLine:=CmdLine + ' -sid ' + IntToStr(FSubIDs.SelectedId);

  // DVD DEVICE AND CACHE
  if IsDvd then
    if sFile[2] = ' ' then
      CmdLine:=CmdLine+ ' -dvd-device ' + copy(sFile,1,1) + ': -dvdangle 1';

  cachesize := CacheSizeCmd(sFile);
  if cachesize > 0 then
    CmdLine:=CmdLine+ ' -cache '+ inttostr(cachesize)
  else
    if cachesize = 0 then CmdLine:=CmdLine+ ' -nocache ';

  // AUDIO FILTERS
  if FAudioFilterChannels <> '' then
    CmdLine:=CmdLine+' -af channels=' + FAudioFilterChannels;
  // VIDEO FILTERS
  case  DeinterlaceCmd(Fdeinterlace, FDeinterlaceAlg, FDeinterlaceDvd, IsDvd, Interlaced) of
    1:CmdLine:=CmdLine+' -vf-add pp=lb';
    2:CmdLine:=CmdLine+' -vf-add pp=fd';
    3:CmdLine:=CmdLine+' -vf-add kerndeint';
    4:CmdLine:=CmdLine+' -vf-add yadif=1';
  end;

  case FPostproc of
    1:CmdLine:=CmdLine+' -autoq 10 -vf-add pp';
    2:CmdLine:=CmdLine+' -vf-add pp=hb/vb/dr';
  end;
  if Fvideoeq <> '' then
     CmdLine := CmdLine + ' -vf-add ' + Fvideoeq;

  if (not check) and wasInError and
      FTryScaler and (not FScalerTried) then
    scaler := true
  else begin
    scaler := false;
    case FVideoScaler of
      1:scaler := true;
      2:if ansipos('gl', sVideoOut)> 0 then
        if (ansipos('kerndeint',CmdLine) > 0) or
         (ansipos('yadif',CmdLine) > 0) then
            scaler := true;
    end;
  end;


  if scaler then
    CmdLine := CmdLine + ' -vf-add scale';

  CmdLine:=CmdLine+' -vf-add screenshot';

  // ADDIONAL PARAMS
  if length(FParams)>0 then
    CmdLine:=CmdLine+#32+FParams;
  // MEDIA FILE

  if FirstOpenCmd = '' then //no prev command line
    Result := true
  else
    Result := FirstOpenCmd = CmdLine;

  if not check then
    FirstOpenCmd := CmdLine; //update prev command line

  if IsDvd then
    CmdLine:=CmdLine+#32 + copy(sFile,ansipos('dvd',sFile),10)
  else
    CmdLine:=CmdLine+#32 + escapeparam(sFile);

  if not check then begin
    Streaminfo.IsDvd := IsDvd;
    Streaminfo.IsDvdNav := IsDvdnav;
    Frenderinfo.IsPlayingDVDMenu := IsDvdnav;
    Streaminfo.stream.length := filelength;
    Streaminfo.Video.Interlaced := Interlaced;
    if not IsDvd then
      FSecondPosInvalid := Not isfileseekable(sFile);
    Frenderinfo.HasVideoOverlay := HasVideoOverlay;
    FScalerTried := scaler;
  end;

end;

procedure Tmplayer.Start(fromcue : boolean = false);

var D1,D2,DummyPipe1,DummyPipe2:THandle;
    si:TStartupInfo;
    pi:TProcessInformation;
    sec:TSecurityAttributes;
    CmdLine,s:string;
    Success:boolean; Error:DWORD;
    ErrorMessage:array[0..1023]of char;
    wasInerror : boolean;
    i : integer;
    cmdOk : boolean;
begin
  if not fromcue then begin
    if pr.ClientProcess<>0 then exit;
    if length(FMediaFile)=0 then exit;
  end else begin
    FirstOpen := true;
    FMediafile := FFileLoaded;
  end;

  if FirstOpen then begin
    ResetIdsInfo;
  end else begin
    if LastSelSubId<>-2 then
      LastSelSubId := FsubIds.SelectedId;

    for I := 0 to FsubIds.Count - 1 do begin
      if fSubIds.FItems[i].Fvalue[0] = 2  then begin
        FsubLoaded := fSubIds.FItems[i].Text; // save last open sub
        break;
      end;
    end;
  end;
  FsubIds.Clear; // always reset subtitle info

  wasInerror := status = sErrorRetry;

  // initialize stream and status info
  ResetStreaminfo;
  ResetStatusinfo;
  ResumeSeek := 0;

  Streaminfo.FileName := Fmediafile;
  Setstatus(sOpening); //MainForm.UpdateStatus;
  DoOnLogClear;

  if not fromcue then FirstOpenCmd := '';

  cmdOk := CreateCmdLine(Fmediafile,CmdLine,wasInerror);

  if cmdOk then begin
    if fromcue then
      DoOnLog('command line (from initial load):', false)
    else
      DoOnLog('command line:', false);

    s:=CmdLine;
    while length(s)>0 do
      DoOnLog(SplitLine(s), false);
    DoOnLog('');
  end else begin
    SendQuitCommand();
  end;


  if cmdOk and (not fromcue) then begin
    ResetLogLastMsg;
    pr.LastCacheFill:='';

    // create pipes

    with sec do begin
      nLength:=sizeof(sec);
      lpSecurityDescriptor:=nil;
      bInheritHandle:=true;
    end;
    CreatePipe(pr.ReadPipe,DummyPipe1,@sec,0); //D1:=pr.ReadPipe;

    with sec do begin
      nLength:=sizeof(sec);
      lpSecurityDescriptor:=nil;
      bInheritHandle:=true;
    end;
    CreatePipe(DummyPipe2,pr.WritePipe,@sec,0);//D2:=pr.WritePipe;
    // create process
    FillChar(si,sizeof(si),0);
    si.cb:=sizeof(si);
    si.dwFlags:=STARTF_USESTDHANDLES;
    si.hStdInput:=DummyPipe2;
    si.hStdOutput:=DummyPipe1;
    si.hStdError:=DummyPipe1;
    //ShotDir
    Success:=CreateProcess(nil,PChar(CmdLine),nil,nil,true,DETACHED_PROCESS,nil,PChar(FMplayerPath),si,pi);
    //Success:=CreateProcess(nil,PChar(CmdLine),nil,nil,true,DETACHED_PROCESS,nil,ShotDir,si,pi);
    Error:=GetLastError();

    CloseHandle(DummyPipe1);
    CloseHandle(DummyPipe2);

    pr.ClientWaitThread := nil;
    pr.Processor := nil;
    if not Success then begin
      DoOnLog('Error '+IntToStr(Error)+' while starting MPlayer:');
      FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,nil,Error,0,@ErrorMessage[0],1023,nil);
      DoOnLog(ErrorMessage);
      if Error=2 then DoOnLog('Please check if MPlayer.exe is installed in the same directory as MPUI.');
      ClientDone(nil);  // this is a synchronized function, so I may
                                  // call it here from this thread as well
      exit;
    end;

    FMplayerProcessId := pi.dwProcessId;
    FMplayerThreadId := pi.dwThreadId;

    pr.FirstChance:=true;
    pr.ClientWaitThread:=TClientWaitThread.Create(true);
    pr.ClientWaitThread.exitCode := 0;
    pr.ClientWaitThread.FreeOnTerminate := true;
    pr.ClientWaitThread.OnTerminate := self.clientDone;

    pr.Processor:=TProcessor.Create(true);
    pr.Processor.FreeOnTerminate := true;
    pr.Processor.OnNewdata := HandleInputLine;


    pr.ClientProcess:=pi.hProcess;
    pr.ClientWaitThread.hProcess:=pr.ClientProcess;
    pr.Processor.hPipe:=pr.ReadPipe;

    pr.ClientWaitThread.Resume;
    pr.Processor.Resume;

  end; // end check for cue file
  fFileLoaded := '';
end;

procedure Tmplayer.Restart(Reload : boolean = false);
var LastPos :int64; //LastOSD:integer;
   resumetype : integer;
   LastSecond : integer;
   LastSecondExt : integer;
   LastPercent : integer;
begin
  if (not Running) and (not Reload) then exit;
  //****visenri

  if not Reload then begin
    if (Streaminfo.DurationMP = 0) or SecondPosInvalid then begin
    //    if StreamInfo.stream.length > 0 then begin ; for testing
      if Streaminfo.stream.length <= 0 then begin
        LastPos := (FPercentPos + 500) div 1000;
        resumetype := 1;
      end else begin
        if FUseSeekbystream then begin
          resumetype := 3;
          lastpos := FStreamPos
        end else begin
          resumetype := 4;
          lastpos := FSecondPosMP-2
        end;
      end;
    end else begin
      resumetype := 2;
      Lastpos := FSecondPosMP -2;
      if lastpos < 0 then lastpos := 0;
    end;
    if Running then begin
      StopAndWaitForDone;
      //ForceStop;
      //Sleep(50); // wait for the processing threads to finish
      //Application.ProcessMessages; //let VCL process thread termination events
      //CheckSynchronize;
    end;
  end else begin
    //backup seek command for new reload
    resumetype := ResumeSeek;
    lastpos := ResumeSeekPos;
  end;
  LastSecond := FSecondPosMP;
  LastSecondExt := FSecondPosExt;
  LastPercent := FPercentPos;

  Start;
  //**** store variables for later send
  ResumeSeek := resumetype;
  ResumeSeekPos := lastpos;
  ResumeseekSecond := LastSecond;
  ResumeseekSecondExt := LastSecondExt;
  ResumeseekPercent := LastPercent;
end;

function Tmplayer.StartNewDVDMedia(nexttitle : boolean = false) : boolean;
var oldstr, newstr, media: string; pos : integer;
begin
   Result := false;
   if Streaminfo.IsDvd then begin

     if FUseDvdNav then begin
      oldstr := SRC_FILE_DVD;
      newstr := SRC_FILE_DVDNAV;
     end else begin
      oldstr := SRC_FILE_DVDNAV;
      newstr := SRC_FILE_DVD;
     end;
     media := StringReplace(Fmediafile , oldstr,newstr, [rfIgnoreCase]);

     if newstr = SRC_FILE_DVD then begin
       pos := ansipos(newstr,media);
       if pos > 0 then begin
         media := leftstr(media,pos + length(newstr)-1);
         pos := 1;
         if TitleIds.Count > 1 then begin
          if nexttitle then
            if(TitleIds.Selected+1) < Titleids.Count  then begin
              TitleIds.SetSelected (TitleIds.Selected+1);
              Result := true;
            end;
          if TitleIds.SelectedId > 0 then
            pos := TitleIds.SelectedId;
         end;
         media := media + inttostr(pos);
         //media := media + '1-99';
       end;
     end;
     if Result or (not nexttitle) then begin
       Result := true;
       Playmedia(media);
     end;
   end;
end;
procedure Tmplayer.Playmedia(media: string);
begin
  if Running then begin
    StopAndWaitForDone;
    //if isvideofileDVD(media) then begin
      //Forcestop;
      //Sleep(50); // wait for the processing threads to finish
      //Application.ProcessMessages;  // let the VCL process the finish messages
      //CheckSynchronize;
    //end else begin  //future use, load file in running mplayer
    //  sendLoadFileCommand(media,false);
    //  exit;
    //end;
  end;

  if isvideofileDVD(media) then
  if not isvideofileDVDNAV(media) and FUseDvdNav then begin
    media := StringReplace(media , SRC_FILE_DVD,SRC_FILE_DVDNAV, [rfIgnoreCase]);
    FirstOpen := true;
  end;

  if FmediaFile <> media then
    FirstOpen := true;
  Fmediafile := media;
  start;
end;
procedure Tmplayer.Closemedia;
begin
  Fmediafile := '';
  if running  then
    Stop
  else
    setStatus(sNone);
end;

procedure Tmplayer.Terminate;
begin
  if pr.ClientProcess=0 then exit;
  TerminateProcess(pr.ClientProcess,cardinal(-1));
end;

procedure Tmplayer.ResumeplayStatus;
begin
  if Running  then
    if Status = sPaused then
      SendPauseCommand;
end;
procedure Tmplayer.SendPlayPause;
begin
  if FPause then begin //want paused
    if (FStatus <> sPaused) then begin //not paused
      sendPauseCommand;
      setstatus(sPaused);
    end;
  end else begin
    if FStatus in [sPaused, sPlayStarting] then begin // paused or starting
      if Fstatus <> sPlayStarting then sendPauseCommand;
      setstatus(sPlaying)
    end;
  end;
end;
//procedure Tmplayer.Unpause;
//begin
//  if Status = sPaused then begin
//    sendPauseCommand;
//    setstatus(sPlaying);
//  end;
//end;
procedure Tmplayer.FrameStep;
begin
  if Status = sPaused then begin
    //sendFrameStepCommand;
    DidFramestep := true;
    DelayPositionQueries := 0;
    QueryPosition;
  end;
end;

procedure Tmplayer.seekto(value: int64; method : integer);
var secmp : integer;
begin
  if (Status = sPaused) or (Status = sPlaying) then begin
    if (method = 2) or (method = 4) then begin
      secmp := CalcSecondPosMp(value);
      SendSeekcommand(secmp,method);
      DoonSecondPosition(value,true);
      DelayPositionQueries :=  4;
      //doonlog('seek to ' + inttostr(value));//-d-
//      if (Streaminfo.IsMp3) and (Method = 4) then
//        DelayPositionQueries :=  20;
    end else begin
      SendSeekcommand(value,method);
      if method = 3 then
        DelayPositionQueries :=  1
      else
        DelayPositionQueries :=  8;
    end;
    SetStatus(sPlaying);
  end;
end;
procedure Tmplayer.seekBy(Value : integer);
begin
  if (Status = sPaused) or (Status = sPlaying) then begin
    sendseekInccommand(Value);
    SetStatus(sPlaying);
  end;
end;
procedure Tmplayer.Stop;
begin
  if running then begin
    setstatus(sClosing); //MainForm.UpdateStatus;
    pr.ExplicitStop:=true;
    if pr.FirstChance then begin
      SendQuitCommand;
      pr.FirstChance:=false;
    end else
      Terminate;
  end;
end;
procedure Tmplayer.StopAndWaitForDone;
var
  waitResult : DWORD;
  waitHandle : THandle;
begin
  if running then begin
    pr.ExplicitStop:=true;
    SendQuitCommand;
    pr.FirstChance:=false;
    // save handle of wait thread, to wait for it later
    // after calling CheckSynchronize ClientWaitThread may be already destroyed
    waitHandle := pr.ClientWaitThread.Handle;
    // wait for client process to finish
    waitResult := WaitForSingleObject(pr.ClientProcess,5000);

    if waitResult = WAIT_TIMEOUT then begin // terminate, forced close
      Terminate;
    end;
    Sleep(5);
    repeat
      CheckSynchronize();
      if running then
        Sleep(5);
    until not running;

    WaitForSingleObject(waitHandle,5000);
    CheckSynchronize();
  end;
end;

function Tmplayer.DVDgoMenu(): boolean;
begin
  if (FStatus = sPlaying) and Streaminfo.IsDvdNav then begin
    SendCommand('dvdnav menu');
    result := true;
  end else result := false;
end;

function Tmplayer.DVDMenuClick: boolean;
begin
  if (FStatus = sPlaying) and FRenderinfo.IsPlayingDVDMenu then begin
    SendCommand('dvdnav mouse');
    doonlog('dvdnav mouse');
    result := true;
  end else result := false;
end;

function Tmplayer.DVDMenuPostition(x, y: integer) : boolean;
begin
  if (FStatus = sPlaying) and FRenderinfo.IsPlayingDVDMenu then begin
    SendCommand('set_mouse_pos ' + inttostr(x) + ' ' +inttostr (y));
    result := true;
  end else result := false;
end;

procedure Tmplayer.DoOnlog(str : string; fromMpui: boolean = true);
begin
  if assigned(FOnlog) then
    if fromMpui then
      FOnlog(self, '3nity: ' + str)
    else
      FOnlog(self,str);
end;
procedure Tmplayer.DoOnlogClear();
begin
  if assigned(FOnlogClear) then
    FOnlogClear(self);
end;

procedure Tmplayer.DoOnOverlayChange(required: boolean; color: Tcolor);
begin
  if assigned(FOnOverlayChange) then
     FOnOverlayChange(self, required, color);
end;
procedure Tmplayer.DoOnVideoSizeChanged();begin
  if assigned(FOnVideoSizeChanged) then
    FOnVideoSizeChanged(self);
end;

procedure Tmplayer.DoOnPercentPosition(value : integer;forced : boolean = false);begin
  if forced or (delaypositionQueries = 0) then
    if forced or (Value <> FPercentPos) then begin
      FPercentPos := Value;
      if assigned(FOnPercentPosition) then
        FOnPercentPosition(self);
    end;
end;
procedure Tmplayer.DoOnSecondPosition(value: integer;forced : boolean = false);
var
 strFile : string;
 newCmd : string;
begin
  if forced then begin
    FSecondPosMp := CalcSecondPosMp(value);
  end else begin
    FSecondPosMp := value;
    value := CalcSecondPosExt(FSecondPosMp);
    if delayPositionqueries <> 0 then exit;
  end;
  if forced or (Value <> FSecondPosExt) then begin
    FSecondPosExt := value;
    if FfileLoaded ='' then
      if (FsecondPosExt > 5) and (FSecondPosExt > (Streaminfo.DurationExt -5)) then
        if assigned(FOnLoadNextFile) then begin
          FOnLoadNextFile(self,strFile);
          if strFile <> '' then begin
             if CreateCmdLine(strFile,newCmd,false,true)  then
               sendLoadFileCommand(strFile)
             else begin
               FFileloaded :='-';
               Doonlog('Reuse of mplayer rejected, command line arguments will be different');
             end;
          end;
        end;
    if assigned(FOnSecondPosition) then
      FOnSecondPosition(self);
  end;
end;

procedure Tmplayer.DoOnAudioChange(id : integer);
begin
  if assigned(FOnAudioChange) then
    FOnAudioChange(self,id);
end;
procedure Tmplayer.DoOnsubAdded(id: integer);
begin
  if assigned(FOnsubAdded) then
    FOnsubAdded(self, id);
end;
procedure Tmplayer.DoOnSubChange(id: integer);
begin
  if Assigned(FOnsubChange) then
    FOnsubChange(self,id);
end;

procedure Tmplayer.DoOnProgress(const name : string; const value : string);
begin
  if assigned(FOnprogress) then
    FOnProgress(self,name,value);
end;



procedure Tmplayer.ResetLogLastMsg();
begin
  pr.LastLine:=''; pr.LineRepeatCount:=0;
end;

procedure Tmplayer.LogInvalidPos(time : integer);
begin
  if time > (Streaminfo.DurationMP + 10) then
    DoOnlog('Time stamp greater than media duration: ' +
                  SecondsToTimeHMS(time) )
  else
    DoOnlog('Starting time is not 0: ' +
                  SecondsToTimeHMS(time) );

  DoOnlog('Using alternate seek method');
end;

function getStringValue (const str : string; const sepstr : string = '='; const endstr : string = '') : string;
var pos : integer;
begin
  if sepstr <> '' then
    pos := ansipos(sepstr,str)
  else
    pos := 0;
  if (pos > 0) or (sepstr = '') then begin
    if pos > 0 then
      Result := RightStr(str, length(str) - pos - length(sepstr)+1)
    else
      Result := str;
    if endstr <> '' then begin
      pos := ansipos(endstr, Result);
      if pos > 0 then
        Result := LeftStr(Result,pos-1);
    end;
  end else
    Result := ''
end;
function getStringValueInteger(const str : string; var value : integer;const sepstr : string = '=';const endstr : string = ''): boolean;
begin
  try
    Result := true;
    value := strtoint(getstringvalue(str,sepstr,endstr));
  except
    Result := false;
    value := 0;
  end;
end;
function getStringValueInt64(const str : string; var value : int64;const sepstr : string = '=';const  endstr : string = ''): boolean;
begin
  try
    Result := true;
    value := strtoint64(getstringvalue(str,sepstr,endstr));
  except
    Result := false;
    value := 0;
  end;
end;
function getStringValueFloat(const str : string; var value : single;const sepstr : string = '=';const  endstr : string = ''): boolean;
begin
  try
    Result := true;
    value := StrToFloat(getstringvalue(str,sepstr,endstr));
  except
    Result := false;
    value := 0;
  end;
end;

function Tmplayer.audio_stream_audio_format(fmt : string) : string;
var layer: string;
    cnt : integer;
begin
  result := '';
  fmt := uppercase(fmt);

  if ansipos ('DIVX', fmt) > 0 then
    result := 'WMA'
  else if ansipos('FFMPEG ', fmt)> 0 then
    result:=trim(getStringValue(fmt,'MPEG','AUDIO'))
  else if ansipos('AAC',fmt)>0 then
    result := 'AAC'
  else if ansipos('AC3',fmt) > 0 then begin
    result := 'AC3';
  end else if ansipos('DTS',fmt) > 0 then
    result := 'DTS'
  else if ansipos ('PCM', fmt) > 0 then
    result := 'LPCM'
  else if ansipos ('WMA', fmt) > 0 then
    result := 'WMA9'
  else if ansipos ('VORBIS', fmt)> 0 then
    result := 'VORBIS'
  else if ansipos('MPEG',fmt)> 0 then begin
    fmt:=getStringValue(fmt,'MPEG');
    layer := '';
    for cnt := 1 to 4 do begin
      if ansipos(inttostr(cnt), fmt) > 0 then
        layer := layer + '/' + 'L' + inttostr(cnt);
    end;
    result := 'MPEG' + layer;
  end;
  if result ='' then
    result := fmt

end;
function Tmplayer.audio_stream_mpg_format(id : integer): string;
var
  text :string;
begin
  text := '';
  if isvideofilempg(StreamInfo.FileName) or Streaminfo.IsDvd then
    case id of
    0..31:
      text := 'MPEG';
    128..159:
      text := 'AC3';
    160..191:
      text := 'LPCM';
    end;
   Result := text;
end;

procedure Tmplayer.SetCurrentAudioStreamFormat();
  var ind : integer;
      newtext : string;
  begin
   if audioids.Count > 0 then begin
    if audioids.Count = 1 then begin
      ind := 0
    end else begin
      ind := audioids.ActualIndex;
    end;
    if ind >= 0 then begin
      newtext := audio_stream_audio_format(Streaminfo.Audio.Codec);
      if (audioids.FItems[ind].Ftext = '') or
         (ansipos(audioids.FItems[ind].Ftext, newtext) > 0) then begin
        Faudioids.FItems[ind].Ftext := newtext;
        Faudioids.FItems[ind].Fvalue[0]:= Streaminfo.Audio.Channels;
      end;
    end;
   end;
end;

procedure Tmplayer.sendcmdsInit(cmdset : integer);
    function findnotAvailableAudio(max: integer) : integer;
    var i : integer;
    begin
      i := max;
      while i > 0 do
        if Audioids.FindId(i) >= 0 then
          dec(i)
        else
          break;
      result := i;
    end;
  begin
    if cmdIniSent = 2 then exit;

    //check if audio init
    if (cmdset > 0) and (cmdIniSent <= 0) then begin
      if AudioOut>1 then begin
        if isAudioSwitchNoRestart then
          SendProperty('switch_audio',  findnotAvailableAudio(255), 1)  //get selected audio track by changing to actual
        else
          //if FaudioIDs.Count > 1 then
          RequestProperty('switch_audio');
//        if Volume<>LastVolume then
        SendVolumeCommandSoftVol(Volume);
        if Mute then SendVolumeMuteCommand();
      end;
      cmdIniSent := 1;
    end;
    //check if video/other init
    if (cmdset > 1) and (cmdIniSent = 1) then begin
      SetOSDLevel(FOSDLevel);

      if CmdIniRetry = 0 then begin

        if Resumeseek > 0 then begin
          sendseekcommand(resumeseekPos, resumeseek);
          if resumeseek >= 3 then
            FSecondposinvalid := true;
          FSecondPosMP := 0;
          FSecondPosExt := 0;
          //MainForm.QueryPosition;
        end else begin
          if isvideoformatLavf then begin //seek to 0 to avoid file error with 3gp videos and gl2
            if isVideofile3gp(StreamInfo.FileName) then begin
              sendseekcommand(0,1);
              FSecondPosMP := 0;
              FSecondPosExt := 0;
            end;
          end;
        end;

        if (Resumeseek = 0) and (FSecondPosMP = -1) then
          requestProperty('time_pos', false); //get initial time for checking
      end;

      getEqActualPropertys();
      if not isAudioSwitchNoRestart then
        SetCurrentAudioStreamFormat();

      setstatus(sPlayStarting);

      if fsubids.Count > 0 then begin
        if LastSelSubId >= 0 then begin //select last selected subtitle
          SetSubIDint(LastSelSubId);
          if FsubIds.SelectedId >= 0 then // last selected not available or manually loaded
            LastSelSubId := -1;
        end;
        if SubIds.FactualId < 0 then //select first available track or no subtitle
          if FsubLoaded = '' then begin
            SelectSubTrack(subIds.FItems[0].id,true);
          end;
      end;

      if FsubLoaded <> '' then
        sendLoadSubCommand(FsubLoaded);

      cmdIniSent := 2;
      cmdIniRetry := 0;
      FirstOpen := false;

      requestProperty('stream_start');

      if streaminfo.stream.length < 0 then
        requestProperty('stream_length');

      requestProperty('length');

      sendSpeedCommand(FSpeed);
    end;
  end;


procedure Tmplayer.HandleInputLine(Line:string);
var r,i,j,p:integer; c:char;
   SecondPosReal : single;

  procedure ItemIds_SetLang(group : TItemIds; ID:integer; Lang:string);
  var ind:integer;
  begin
    ind := group.FindId(ID);
    if ind >= 0 then
      group.Items[ind].Flang := Lang;
  end;
  procedure ItemIds_SetText(group : TItemIds; ID:integer; txt:string);
  var ind:integer;
  begin
    ind := group.FindId(ID);
    if ind >= 0 then
      group.Items[ind].Ftext := txt;
  end;
  function checkNoaspect() : boolean;
  begin
    Result := false;
    if Ansipos('Movie-Aspect is undefined',Line) > 0 then begin
      fixaspect(-1);
      result := true;
    end;
  end;

  function checkEqPropertys(const name : string; value : integer; failed : boolean): boolean;
  var i : integer;
  begin
    Result:=false;
    if defaultreadini = 0 then exit;

    for i := 0 to high(propertyEntrys) do begin
        if name = propertyEntrys[i].name    then begin
          if not failed then begin
            Fpropertyvalues[i].default := value;
            Fpropertyvalues[i].valid  := true;
            DoOnLog('Default ''' + name + ''' = ' + inttostr(Fpropertyvalues[i].default));
          end else begin
            Fpropertyvalues[i].default := 0;
            Fpropertyvalues[i].valid := false;
            DoOnLog('Property ''' + name + ''' not available in actual video mode');
          end;
          //settingsform.EnableSetting(i,validprop[i]);

          defaultreadini := defaultreadini -1;
          if defaultreadini = 0 then begin
            checksetEqPropertys;
            if assigned( FOnPropertysRead) then
               FOnPropertysRead(self)
          end;
          Result:=true;
          exit;
        end;
    end;

  end;

  function CheckNativeResolutionLine:boolean;
    function getResolution(afterchars: string; str : string; var w : integer; var h : integer): boolean;
    begin
      Result := false;
      p:=Pos(afterchars,str); if p=0 then exit; Delete(str,1,p+length(afterchars)-1);
      p:=Pos(#32,str);    if p=0 then exit; SetLength(str,p-1);
      p:=Pos('x',str);    if p=0 then exit;
      Val(Copy(str,1,p-1),i,r); if (r<>0) OR (i<16) OR (i>=4096) then exit;
      Val(Copy(str,p+1,5),j,r); if (r<>0) OR (j<16) OR (j>=4096) then exit;
      Result := true;
    end;
  begin
    Result:=false;
    if Copy(Line,1,5)<>'VO: [' then exit;

    if not getResolution(' => ', line, i,j) then exit;
    FRenderInfo.Width :=i; FRenderInfo.Height :=j;
    if Streaminfo.Video.Width = 0 then begin
      if not getResolution('] ', line, i,j) then exit;
      Streaminfo.Video.Width := i;
      Streaminfo.Video.Height := j;
    end;


    //MainForm.VideoSizeChanged;
    DoOnVideoSizeChanged;
    Result:=true;
    if cmdiniSent = 1 then
      sendcmdsInit(2)
    else
      cmdiniSent := -1;

    fixaspect(-1);
  end;

  function CheckNoAudio:boolean;
  begin
    Result:=false;
    if Line<>'Audio: no sound' then exit;
    Streaminfo.HaveAudio:=false;
    Result:=true;
  end;

  function CheckNoVideo:boolean;
  begin
    Result:=false;
    if Line<>'Video: no video' then exit;
    Streaminfo.HaveVideo:=false;
    Result:=true;
  end;

  function CheckStartPlayback:boolean;
  begin
    Result:=false;
    if Line<>'Starting playback...' then exit;
    //MainForm.SetupPlay;
    Streaminfo.Valid := true;

    if Streaminfo.HaveVideo and (cmdinisent = 0) then
      sendcmdsInit(1)
    else begin
      sendcmdsInit(2);
    end;

    Result:=true;
  end;
  function CheckNewFileLoad: boolean;
  begin
    result := false;
    if FfileLoaded <> '' then
      if ansipos('Playing ',Line)=1 then begin
        if assigned(FOnFileLoaded) then
          FOnFileLoaded(self, Ffileloaded);
        if Ffileloaded <> '' then
          Start(true)
        else
          SendQuitCommand();
        doonlog(Line, false);
        result := true;
      end;

  end;
  function checkAudioFormatMkv: boolean;
  var fmt : string;
      id : integer;
  begin
    result := false;
    if ansipos('[mkv]',line) = 1 then
      if ansipos('audio',getStringValue(line,':', '('))> 0 then begin
        fmt := getStringValue(line,'(A_',')');
        if (fmt <> '') and getStringValueInteger(line,id,'-aid',',') then begin
          fmt := audio_stream_audio_format(fmt);
          ItemIds_SetText(AudioIds,id,fmt);
          result := true;
        end;
      end;
  end;
  function CheckAudioID:boolean;
  begin
    Result:=false;
    if Copy(Line,1,12)='ID_AUDIO_ID=' then begin
      Val(Copy(Line,13,9),i,r);
      if (r=0) AND (i>=0) AND (i<8191) then begin
        if firstopen then
          if AudioIds.FindId(i) = -1 then
            AudioIds.Add(i, audio_stream_mpg_format(i));
        Result:=true;
      end;
    end;
  end;

  function CheckAudioLang:boolean;
  var s:string; p:integer;
  begin
    Result:=false;
    if Copy(Line,1,7)='ID_AID_' then begin
      s:=Copy(Line,8,20);
      p:=Pos('_LANG=',s);
      if p<=0 then exit;
      Val(Copy(s,1,p-1),i,r);
      //if (r=0) AND (i>=0) AND (i<256) then begin
      if (r=0) AND (i>=0) AND (i < 256) AND (audioids.Count < 256) then begin
       ItemIds_SetLang(AudioIds,i,copy(s,p+6,8));
       Result:=true;
      end;
    end;
  end;
  function CheckSubID:boolean;
  var
    s : string;
  begin
    Result:=false;
    if (Copy(Line,1,15)='ID_SUBTITLE_ID=') or
       (Copy(Line,1,15)='ID_FILE_SUB_ID=') then begin
      Val(Copy(Line,16,9),i,r);
      if Copy(Line,4,1)='F' then
        s := ''
      else
        s := IntToStr(i);

      //if (r=0) AND (i>=0) AND (i<256) then begin
      if (r=0) AND (i>=0) AND (i<256) AND (subids.Count < 256) then begin
        //if firstopen then begin
          inc(i);
          if Copy(Line,4,1)='F' then
            if subids.Count>0 then
              i := subids.Count;
          if SubIds.Count=0 then
            SubIds.Add(0); // add null subtitle

          if subIds.FindId(i)< 0  then
            SubIds.Add(i,s);

          DoOnsubAdded(i);
        //end;
        Result:=true;
      end;
    end;
  end;

  procedure RestoreSubScale;
  begin
    SendProperty(propertyEntrys[PROP_SUB_SCALE].name,
                 propertyValues[PROP_SUB_SCALE].Value/
                 propertyEntrys[PROP_SUB_SCALE].scale ,1);
  end;

  function CheckSubFilename: boolean;
  var
    s : string;
  begin
    result := false;
    if (Copy(Line,1,21)='ID_FILE_SUB_FILENAME=') then begin
      s := getStringValue(Line);
      s := stringreplace(s,'/','\',[rfReplaceAll]);
      if SubIds.Count > 0 then
        if SubIds.Items[SubIds.Count -1].text = '' then begin
          SubIds.FItems[SubIds.Count -1].Ftext := s;
          if (FsubLoaded = '') or (Fstatus = sOpening) then begin
            subIds.FItems[SubIds.Count -1].Fvalue[0] := 1;
            SelectSubTrack(subIds.FItems[SubIds.Count -1].id);
          end else begin
            subIds.FItems[SubIds.Count -1].Fvalue[0] := 2;
            FsubLoaded := '';
            if(LastSelSubId = subIds.FItems[SubIds.Count -1].id) or (LastSelSubId = -2) then begin
              SetSubIDint(subIds.FItems[SubIds.Count -1].id);
              LastSelSubId := -1;
            end;
            RestoreSubScale;
          end;
          DoOnsubAdded(SubIds.Count -1);
          result := true;
        end;
    end;

  end;
  function CheckSubLoadError : boolean;
  begin
    result := false;
    if copy(line,1,4) = 'SUB:' then
      if ansipos('Could not determine file format',line)>0 then begin
        FsubLoaded := '';
        RestoreSubScale;
        SendOsdShowCommand(line,2500);
        result := true;
      end;
  end;
  function CheckSubLang:boolean;
  var s,st : string; ind:integer;
  begin
    Result:=false;
    if Copy(Line,1,7)='ID_SID_' then begin
      s := getStringValue(Line,'ID_SID_');
      if getStringValueInteger(Line, ind,'ID_SID_','_') then begin
        st := getstringValue(s);
        s := trim(getStringValue(s,'_','='));

        ind := SubIds.FindId(ind+1);
        if ind >= 0 then
          if s = 'LANG' then
            subIds.FItems[ind].Flang := st
          else if s = 'NAME' then
            subIds.FItems[ind].Ftext := st;
      end;
    end;
  end;

  function CheckLength(const name : string; fromId : boolean; failed : boolean):boolean;
  var f:single; CorrectLenght : boolean;
  begin
    result := Uppercase(name) = 'LENGTH';
    if Result then begin
      if failed then
        f := Streaminfo.DurationMP
      else
        getStringValueFloat(Line,f);

      if (not fromId) and (Streaminfo.DurationMP <= 0) then begin
        FUseSeekbystream := true;
        DoOnlog('Time Duration is 0, using alternate seek method (stream pos)');
        if Streaminfo.stream.length > 0 then
          FSecondPosInvalid := true;
      end else begin
        Streaminfo.DurationMP := Correctround(f);
        CorrectLenght := false;
        if not(fromId) and (Streaminfo.DurationMP > 0)  then begin
          CorrectLenght := abs(Streaminfo.DurationMP -  Streaminfo.DurationExt)
                           > (Streaminfo.DurationMP div 100);
        end;
        if (Streaminfo.DurationExt <= 0) then
          Streaminfo.DurationExt := Streaminfo.DurationMP
        else begin
          if (Streaminfo.IsMp3 and (FMp3Info.VbrBitRate >0)) then begin
            if not FSecondPosInvalid then begin
              FSecondPosInvalid := true;
              DoOnlog('Vbr file, using seek by reported length');
            end;
          end else begin
            if CorrectLenght then begin
              FSecondPosInvalid := true;
              FUseSeekbystream := true;
              DoOnlog('Time Duration mismatch, using alternate seek method (stream pos)');
            end;
          end;
        end;
        Streaminfo.Durationstring:=SecondsToTimeHMS(Streaminfo.DurationExt);
      end;
      if (not fromId) and (Fstatus = sPlayStarting) then begin
        if resumeseek >0 then begin
          //restore old percent and second
          FSecondPosMP := ResumeseekSecond;
          FSecondPosExt := ResumeseekSecondExt;
          FPercentPos := ResumeseekPercent;
        end;
        SendPlayPause();
      end;
//        setstatus(sPlaying);// set by sendplaypause
    end;
  end;

  function CheckFileFormat:boolean;
  begin
    p:=length(Line)-21;
    Result:=(p>0) AND (Copy(Line,p,22)=' file format detected.');
    if Result then
      Streaminfo.FileFormat:=Copy(Line,1,p-1);
  end;

  function CheckDecoder:boolean;
  begin
    Result:=(Copy(Line,1,8)='Opening ') AND (Copy(Line,13,12)='o decoder: [');
    if not Result then exit;
    p:=Pos('] ',Line); Result:=(p>24);
    if not Result then exit;
    if Copy(Line,9,4)='vide' then
      Streaminfo.Video.Decoder:=Copy(Line,p+2,length(Line))
    else if Copy(Line,9,4)='audi' then
      Streaminfo.Audio.Decoder:=Copy(Line,p+2,length(Line))
    else Result:=false;

    DoOnProgress(copy(line,1,21),'');
  end;
  function CheckVideoFourcc: boolean;
  var lstr : integer; k: integer;
  begin
   with Streaminfo.Video do begin
    if (pos('VIDEO: ', Line)= 1) or (pos('VIDEO ',Line)=1) then begin
      Fourcc := trim(getstringvalue(Line,' '));
      Fourcc := trim(getstringvalue(Fourcc,'',' ')); ; //get text until space
      lstr := length(Fourcc);
      if lstr > 0 then begin
        // delete invalid start characters, normally '['
        if not( Char(Fourcc[1]) in ['a'..'z', 'A'..'Z', '0'..'9']) then begin
          Fourcc[1] :=' ';
          Fourcc := trim(Fourcc);
          lstr := length(FOurcc);
        end;
        if lstr > 6 then begin //limit max size to 6 chars
          Fourcc := leftstr(Fourcc,6);
          lstr := 6;
        end;
        for k := 1 to lstr do begin  //find last valid character, in ts streams, Video fourcc has no space
          if not( Char(Fourcc[k]) in ['a'..'z', 'A'..'Z', '0'..'9']) then begin
            fourcc := leftstr(fourcc,k-1);
            break;
          end;
        end;

      end;
      Fourcc := trim(Fourcc);
      result := true;
    end else result := false
   end;
  end;

  function CheckCodec:boolean;
  begin
    Result:=(Copy(Line,1,9)='Selected ') AND (Copy(Line,14,10)='o codec: [');
    if not Result then exit;
    p:=Pos(' (',Line); Result:=(p>23);
    if not Result then exit;
    if Copy(Line,10,4)='vide' then
      Streaminfo.Video.Codec:=Copy(Line,p+2,length(Line)-p-2)
    else if Copy(Line,10,4)='audi' then
      Streaminfo.Audio.Codec:=Copy(Line,p+2,length(Line)-p-2)
    else Result:=false;
  end;

  function CheckICYInfo:boolean;  // check! for better implementation
  var P:integer;
  begin
    Result:=False;
    if Copy(Line,1,10)<>'ICY Info: ' then exit;
    P:=Pos('StreamTitle=''',Line); if P<10 then exit;
    Delete(Line,1,P+12);
    P:=Pos(''';',Line); if P<1 then exit;
    SetLength(Line,P-1);
    if length(Line)=0 then exit;
    P:=0; while (P<9)
            AND (length(StreamInfo.ClipInfo[P].Key)>0)
            AND (StreamInfo.ClipInfo[P].Key<>'Title')
          do inc(P);
    Streaminfo.ClipInfo[P].Key:='Title';
    if Streaminfo.ClipInfo[P].Value<>Line then begin
      Streaminfo.ClipInfo[P].Value:=Line;

      //InfoForm.UpdateInfo;
    end;
    Result:=true;
  end;
  function checkStreamIds: boolean;
  begin
    Result := false;
    if copy(Line,1,12) = 'SUBSTREAM_ID' then begin
      Result := true;
      exit;
    end;
    if copy(line,1,10) = 'PROGRAM_ID' then begin
      Result := true;
      exit;
    end;
  end;
  function checkDvdNavIds: boolean;
  begin
    Result := false;
    if Streaminfo.IsDvdNav then
      if copy(line,1,6) = 'DVDNAV' then begin
        if ansipos('_TITLE_IS_MENU',line)>0 then begin
          Frenderinfo.IsPlayingDVDMenu := true;
          result := true;
        end;
        if (not result) and (ansipos('_TITLE_IS_MOVIE',line)>0) then begin
          //if Frenderinfo.IsPlayingDVDMenu then
          //  seekBy(1);
          Frenderinfo.IsPlayingDVDMenu := false;
          result := true;
        end;
        if result then begin
          RequestProperty('LENGTH');
        end;
      end;
  end;

  function checkDvdTitles: boolean;
  var pos : integer; iVal : integer; fVal : single; tit : integer; ind : integer;
  begin
    Result := false;
    if Streaminfo.IsDvd then
      if copy(line,1,7) = 'ID_DVD_' then begin
        getStringValueinteger(line, tit,'DVD_TITLE_','_');
        if tit > 0 then begin // is title property
          ind := Ftitleids.FindId (tit);
          if ind = -1 then
            ind := Ftitleids.Add(tit);
          if ansipos('LENGTH', line) > 0 then begin
            if getStringValueFloat(line,fVal) then begin
               Ftitleids.FItems[ind].Fvalue[2] := CorrectRound(fVal);
            end;
          end else begin
            if getStringValueInteger(line,iVal) then begin
              if ansipos('CHAPTERS', line) > 0  then
                Ftitleids.FItems[ind].Fvalue[0] := iVal;
              if ansipos('ANGLES', line) > 0 then
                Ftitleids.FItems[ind].Fvalue[1] := iVal;
            end;
          end;
        end else begin // other propertys
          pos := ansipos('CURRENT_TITLE=', line);
          if pos > 0 then begin
            getStringValueInteger(line, Frenderinfo.TitleID);
            TitleIds.SetSelectedId(Frenderinfo.TitleID);
          end else
            if ansipos('DISC_ID=', line) > 0 then begin
              Streaminfo.ClipInfo[0].Key := 'DISC ID';
              Streaminfo.ClipInfo[0].Value := getStringValue(line);
            end else if ansipos('VOLUME_ID=', line) > 0 then begin
              Streaminfo.ClipInfo[1].Key := 'VOLUME ID';
              Streaminfo.ClipInfo[1].Value := getStringValue(line);
            end;
        end;
      Result := true;
      end;
  end;
  function checkDVDChapters : boolean;
  var  strList : TStringList; i : integer;dt : TDateTime;
    myHour, myMin, mySec, myMilli : word ; ind : integer;
  begin
    Result := false;
    if Streaminfo.IsDvd then
      if copy(line,1,10) = 'CHAPTERS: ' then begin
         strList := TStringList.Create;
         strList.Delimiter := ',';
         strlist.DelimitedText := rightStr(line,length(line)-10);
         FChapterIDs.Clear;
         for i := 0 to strList.Count-1 do
          if length(strList[i]) > 1 then begin
            ind := FChapterIds.Add(i+1);
            try
              dt := StrToTime(strList[i]);
              DecodeTime(dt, myHour, myMin, mySec, myMilli);
              FchapterIds.FItems[ind].Fvalue[2] := myHour*3600+myMin*60+mySec;
            except
            end;

          end else
            break;
         Result := true;
         strList.Free;
      end;
  end;
  function checkfailedanswers : boolean;
  var ansname : string;
  begin
    Result := false;
    if AnsiPos(STR_PROPERTY_FAILED,Line)> 0 then begin
      ansname := getStringValue(line,'''','''');
      if ansname <> '' then begin
        Result := checkEqPropertys(ansname,0,true);
        if result then exit;
        Result := CheckLength(ansname, false,true);
      end;
    end;
  end;
  function checkanswers : boolean;
  var toint: integer;
      toint64 : int64;
      ansname : string;
  begin
    result := false;
    ansname := getStringValue(line,'ANS_','=');
    if ansname = 'switch_audio' then begin
      if getStringValueInteger(line,toint) then begin
        if toint > 0 then
          SelectAudioTrack(toint);
        result := true;
      end;
    end else if (ansname = 'stream_start') or (ansname = 'stream_length')then begin
      if getStringValueInt64(line,toint64) then begin
        if ansname[8]='s' then
          Streaminfo.stream.start := toint64
        else
          Streaminfo.stream.length := toint64;
        result := true;
      end;
    end else if not CheckLength(ansname,false,false) then begin
      if not getStringValueInteger(line,toint) then
        toint := 0;
      result := checkEqPropertys(ansname,toint,false);
    end;
  end;

(*  function checkDVDErrors : boolean;
  begin
    Result := false;
    if Streaminfo.IsDvdNav then begin
      if not frenderinfo.IsPlayingDVDMenu  then
        if ansipos('error',line)> 0 then begin
          //seekBy(+1);
          Result := true;
        end;
    end;
  end;*)
begin
  //logform.AddLine(Line);
    (*  // time position handled below by ANS_TIME_POSITION  //visenri mod
  // Time position indicators are "first-class citizens", because they
  // make up for 99.999% of all traffic. So we have to handle them *FAST*!
  *)
  if (length(Line)>11) then begin
    if Line[1]=^J then j:=4 else j:=3;
    if ((Line[j-2]='A') OR (Line[j-2]='V')) AND (Line[j-1]=':') then begin
      if FSecondPosInvalid or (Streaminfo.DurationMP  = 0) then exit;

      if Streaminfo.Havevideo  then
       if Line[j-2]<>'V' then begin  // find V if available, A time goes sometimes up and down
        p := j + 11; //check only some characters more
        if p > length(Line) -4  then   //not so far
          p := length(Line) -4;
        for i := j to p do begin
          if Line[i]='V' then begin //v found set new start
            j := i+2;
            break;
          end;
          if Line[i]='A' then       //a-v found, abort search
            break;
        end;
       end;


      p:=0;
      for i:=0 to 7 do begin
        c:=Line[i+j];
        case c of
          '-': begin p:=-1; break; end;
          '0'..'9': p:=p*10+ord(c)-48;
          else begin
              if (c = 'A') or (c = 'V') or ((p>0) and (c=' '))  then
                break;
          end;
        end;

      end;


      if p > 0 then begin
        i := (p*10000 + (Streaminfo.DurationMP shr 1)) div Streaminfo.DurationMP;

        p := (p + 5 ) div 10;

        if (p > (Streaminfo.DurationMP+10)) or
           ((secondpos = -1) and (p > 10)) then begin
           if not Streaminfo.IsDvdNav then begin
             Fpercentpos := 0;
             FSecondPosMP := 0;
             FSecondPosExt := 0;
             FSecondPosInvalid := true;
             LogInvalidPos(p);
           end;
        end else begin
          DoOnSecondPosition(p);
          DoOnPercentPosition(i);
        end;

        if not autoupdate then begin
            Autoupdate := true;
            DoOnLog('Time position automatic update detected');
        end;

       end;

      exit; //
    end;
  end;
  (*
  *)
  // normal line handling: check for "cache fill"
  Line:=Trim(Line);
  if (length(Line)>=18) AND (Line[11]=':') AND (Line[18]='%') AND
     (Copy(Line,1,10)='Cache fill') then begin
    if pr.LastCacheFill = Copy(Line,12,6) then exit;
    pr.LastCacheFill := Copy(Line,12,6);
    //MainForm.LStatus.Caption:=Line;
    DoOnProgress('Cache', pr.LastCacheFill);
    if Copy(pr.LastLine,1,10)<>'Cache fill' then
      DoOnlog(Line, false);
    pr.LastLine := Line;
    Sleep(0);  // "yield"
    exit;
  end else begin
    if pr.LastCacheFill <> '' then begin
      DoOnlog(pr.LastLine, false);
      pr.LastCacheFill := '';
    end;
  end;
  // check for fontscan and index generation
  if length(Line) > 16 then
    if (Line[1]='S') and (Line[2]='c') and (Line[3]='a') then begin
      if ansipos('Scanning file',Line)=1 then
        DoOnProgress('FontScan', getStringValue(Line, 'file'));
    end else begin if (Line[1]='G') and (Line[2]='e') and (Line[3]='n') then
        if ansipos('Generating Index:',Line)=1 then
             DoOnProgress( 'Index' , getStringValue(Line,':'));
    end;

  if Copy(Line,1,4)='ANS_' then begin
  // check second position indicator  ; visenri
   if Copy(Line,1,18)='ANS_TIME_POSITION=' then begin

    if FSecondPosInvalid or (Streaminfo.DurationMP = 0) then exit;

    Val( Copy(Line,19,10),  secondposReal,r  );

    i := Correctround(secondposReal);

    if (secondposReal>=0.01) then begin

          if (i > (Streaminfo.DurationMP +10)) or
             ((secondpos = -1) and (i > 10)) then begin
            if not Streaminfo.IsDvdNav then begin
              Fpercentpos := 0;
              FSecondPosMP := 0;
              FSecondPosExt := 0;
              FSecondPosInvalid := true;
              LogInvalidPos(i);
            end;
          end else begin
            DoOnSecondPosition(i);

            if Streaminfo.DurationMP > 0 then begin
              i := (Correctround(secondposReal * 100000.0) + (Streaminfo.DurationMP shr 1)) div Streaminfo.DurationMP;
              DoOnPercentPosition(i);
            end;
          end;
    end;
    ResetLogLastMsg;
    exit;
   end;
  // check percent_position indicator (hidden from log)

    if Copy(Line,1,21)='ANS_PERCENT_POSITION=' then begin

     if not(FSecondPosInvalid or (Streaminfo.DurationMP = 0)) or
        (StreamInfo.stream.length > 0) then exit;

     Val(Copy(Line,22,4),i,r);
     if (r=0) AND (i>=0) AND (i<=100) then begin
       p:=i*1000;
       if Streaminfo.DurationMP > 0 then
         i := (p*Streaminfo.DurationMP) div 100000
       else
         i := 0;

       DoOnSecondPosition(i);
       DoOnPercentPosition(p);
     end;
     ResetLogLastMsg;
     exit;
    end;


    if Copy(Line,1,15)='ANS_stream_pos=' then begin

      if not(SecondPosInvalid or (Streaminfo.DurationMP = 0)) or
         (StreamInfo.stream.length <= 0) then exit;

      Fstreampos := strtoint64(trim(Copy(Line,16,20)));

      i := ((Fstreampos - Streaminfo.stream.start ) * Streaminfo.DurationMP)
           div Streaminfo.stream.length;
      p := ((Fstreampos - Streaminfo.stream.start ) * 100000)
           div Streaminfo.stream.length;

      DoOnSecondPosition(i);
      DoOnPercentPosition(p);
      ResetLogLastMsg;
      exit;
    end;
  end;

  //if checkEqPropertys then begin ResetLogLastMsg; exit; end;
  if checkStreamIds then begin ResetLogLastMsg; exit; end; // supress stream ids from log

  // suppress repetitive lines
  if (length(Line)>0) AND (Line=pr.LastLine) then begin
    inc(pr.LineRepeatCount);
    if pr.LineRepeatCount < 2 then // log only 2 reps
      DoOnlog(Line, false);
    exit;
  end;
  if pr.LineRepeatCount>1 then
    DoOnlog('(last message repeated '+IntToStr(pr.LineRepeatCount)+' times)');
  pr.LastLine:=Line;
  pr.LineRepeatCount:=0;
  // add line to log and check for special patterns
  if (length(line) > 0) then
    if (length(line) > 2) or (line[1]<>'[') then
      DoOnlog(Line, false);

  if Copy(Line,1,4)='ANS_' then begin    //check other answers
    if checkanswers then exit;
  end;
  if Copy(Line,1,4) = Copy(STR_PROPERTY_FAILED,1,4) then begin
    if checkfailedanswers then exit;
  end;

  if not CheckNativeResolutionLine then
  if not CheckNoAudio then
  if not CheckNoVideo then
  if not CheckStartPlayback then
  if not CheckAudioID then
  if not CheckAudioLang then
  if not checkAudioFormatMkv then
  if not CheckSubID then
  if not CheckSubFilename then
  if not CheckSubLoadError then
  if not CheckSubLang then
  if not CheckFileFormat then
  if not CheckDecoder then
  if not CheckVideoFourcc then
  if not CheckCodec then
  if not checkNoaspect then
  if not checkDvdNavIds then
  if not checkDvdTitles then
  if not checkDVDChapters then
  if not CheckNewFileLoad then


  if not CheckICYInfo then  // modifies Line, should be last
  ;
  // check for generic ID_ pattern
  if Copy(Line,1,3)='ID_' then begin
    HandleIDLine(getStringValue(Line,'ID_','='), getStringValue(Line));
    CheckLength(getStringValue(Line,'ID_','='),true,false);
    exit;
  end;

  if (ansipos('FATAL: Could not initialize', Line)>0) or
     (ansipos('Cannot find codec', Line) > 0)  then
    if ansipos('video', line)> 0 then
      Frenderinfo.VideoError := true;

  if (ansipos('VDecoder init failed', Line)>0) then
    Frenderinfo.VideoError := true;

  //checkDVDErrors;
end;


procedure Tmplayer.HandleIDLine(ID, Content: string);

var AsInt,r:integer; AsFloat:real;

begin with StreamInfo do begin
  // convert to int and float
  val(Content,AsInt,r);
  if r<>0 then begin
    val(Content,AsFloat,r);
    if r<>0 then begin
      AsInt:=0; AsFloat:=0;
    end else begin
      try
        AsInt:=trunc(AsFloat);
      except
        Asint := 0;
      end;
    end;
  end else begin
    AsFloat:=AsInt;
  end;

  // handle some common ID fields
  //     if ID='FILENAME'      then FileName:=Content
  if ID='VIDEO_BITRATE' then Video.Bitrate:=AsInt
  else if ID='VIDEO_WIDTH'   then Video.Width:=AsInt
  else if ID='VIDEO_HEIGHT'  then Video.Height:=AsInt
  else if ID='VIDEO_FPS'     then Video.FPS:=AsFloat
  else if ID='VIDEO_ASPECT'  then fixaspect(AsFloat)
  else if ID='AUDIO_TRACK' then SelectAudioTrack(AsInt)
  else if ID='AUDIO_BITRATE' then Audio.Bitrate:=AsInt
  else if ID='AUDIO_RATE'    then Audio.Rate:=AsInt
  else if ID='AUDIO_NCH'     then Audio.Channels:=AsInt
  else if (ID='DEMUXER') AND (length(FileFormat)=0) then FileFormat:=Content
  else if (ID='VIDEO_FORMAT') AND (length(Video.Decoder)=0) then Video.Decoder:=Content
  else if (ID='VIDEO_CODEC') AND (length(Video.Codec)=0) then Video.Codec:=Content
  else if (ID='AUDIO_FORMAT') AND (length(Audio.Decoder)=0) then Audio.Decoder:=Content
  else if (ID='AUDIO_CODEC') AND (length(Audio.Codec)=0) then Audio.Codec:=Content
  else if (Copy(ID,1,14)='CLIP_INFO_NAME') AND (length(ID)=15) then begin
    r:=Ord(ID[15])-Ord('0');
    if (r>=0) AND (r<=9) then ClipInfo[r].Key:=Content;
  end else if (Copy(ID,1,15)='CLIP_INFO_VALUE') AND (length(ID)=16) then begin
    r:=Ord(ID[16])-Ord('0');
    if (r>=0) AND (r<=9) then ClipInfo[r].Value:=Content;
  end;
end; end;


procedure Tmplayer.SelectAudioTrack(id : integer);
begin
//  FRenderinfo.AudioId := id;
  AudioIds.FactualId := id;
  SetCurrentAudioStreamFormat();
  DoOnAudioChange(id);
end;
Procedure Tmplayer.SelectSubTrack(id: integer; send : boolean = false);
begin
  if send then
    SendCmd('sub_select ' + intTostr(id-1));
  DoOnlog('sub_select ' + intTostr(id-1));
  //Frenderinfo.SubID := id;
  SubIds.FactualId := id;
  DoOnSubChange(id);
end;

procedure Tmplayer.LoadSubtitle(const filename: string);
begin
  if not isOpening then begin
    sendLoadSubCommand(filename);
    LastSelSubId := -2;
    ResumeplayStatus();
  end;
end;


// *** propertys ***
procedure Tmplayer.StartPropertyChange();begin
  RestartEnabled := false;
end;
procedure Tmplayer.EndPropertyChange();begin
  RestartEnabled := true;
  CheckRestartNeeded(false);
  RestartNeeded := false;
end;
procedure Tmplayer.CheckRestartNeeded(changes : boolean = true);
begin
  if changes and running then
    RestartNeeded := true;
  if RestartNeeded = true then
    if RestartEnabled then
      if FirstOpen and Streaminfo.IsDvd then
        self.StartNewDVDMedia
      else
        Restart;

end;

procedure Tmplayer.CheckRestartNeededByFonts;
begin
  if (ValidFileInfo and Streaminfo.Havevideo) or
     (Self.Status = sOpening) then
    CheckRestartNeeded;
end;

function Tmplayer.GetRunning: boolean;
begin
  result := (pr.ClientProcess <> 0);
end;

procedure Tmplayer.SetmplayerPath(const Value: string);
begin
  if Value <> FmplayerPath then begin
      FmplayerPath := Value;
      CheckRestartNeeded;
  end;
end;
procedure Tmplayer.SetFileLoaded(const Value: string);
begin
  FFileLoaded := Value;
end;
procedure Tmplayer.SetPriorityBoost(const Value: boolean);
begin
  if Value <> FPriorityBoost then begin
      FPriorityBoost:= Value;
      CheckRestartNeeded;
  end;
end;
procedure Tmplayer.SetReIndex(const Value: boolean);
begin
  if Value <> FReIndex then begin
      FReIndex:= Value;
      CheckRestartNeeded;
  end;
end;

procedure Tmplayer.SetAutosync(const Value: integer);
begin
  if value <> FautoSync then begin
    FAutosync := Value;
    CheckRestartNeeded;
  end;
end;

procedure Tmplayer.SetAVsyncPerFrame(const Value: integer);
begin
  if value <> FAVsyncPerFrame then begin
    FAVsyncPerFrame := Value;
    CheckRestartNeeded;
  end;
end;

procedure Tmplayer.SetParams(const Value: string);
begin
  if Value <> FParams  then begin
      FParams := Value;   //should be FParams :=  FParams + ' ' + Value;
      CheckRestartNeeded;
  end;
end;
procedure Tmplayer.SetCachesize(index: integer; const Value: integer);
var oldcache, newcache : integer;
begin
  if (index>=low(FCachesize)) and (index <= high(FCachesize)) then begin
    oldcache := CacheSizeCmd(Fmediafile);
    Fcachesize[index] := Value;
    newcache := CacheSizeCmd(Fmediafile);
    if newcache <> oldcache then
       CheckRestartNeeded;
  end;
end;

procedure Tmplayer.SetFontConfig(const Value: Boolean);
begin
  if FontConfig <> Value then begin
    FFontConfig := Value;
    CheckRestartNeededByFonts;
  end;

end;

procedure Tmplayer.SetFontEncoding(const Value: string);
begin
  if value <> FFontEncoding then begin
    FFontEncoding := Value;
    CheckRestartNeeded;
  end;
end;

procedure Tmplayer.SetFontPath(const Value: string);
begin
  if Value <> FFontPath then begin
    FFontPath := Value;
    CheckRestartNeeded;
  end;
end;

function Tmplayer.GetMplayerWindowHandle: HWnd;
const
  MPLAYER_CLASSNAME = 'MPlayer - Fullscreen';
  MPLAYER_WINDOWNAME = 'MPlayer Fullscreen';

  function DoFindWindow(Window: HWnd; Param: Longint): Bool; stdcall;
  var
    wText : string;
    wSize : Integer;
  begin
    SetLength(wText,256);
    wSize := GetWindowText(Window,PChar(wText),Length(wText));
    SetLength(wText,wSize);
    if wText = MPLAYER_WINDOWNAME then begin
      SetLength(wText,256);
      wSize := GetClassName(Window,PChar(wText),Length(wText));
      SetLength(wText,wSize);
      if wText = MPLAYER_CLASSNAME then begin
        PLongWord(Param)^ := Window;
      end;
    end;
    Result := True;
  end;
var
  wFound : LongWord;
begin
  if Running then begin
    wFound := 0;  // try to find window in created thread
    EnumThreadWindows(FMplayerThreadId, @DoFindWindow, LongWord(@wFound));

    if wFound = 0 then
      // find in all windows
      Result := findwindow(MPLAYER_CLASSNAME,MPLAYER_WINDOWNAME)
    else
      Result := wFound;
  end else begin
    Result := 0;
  end;
end;

function Tmplayer.GetpropertyValues(index: integer): TPropertyValues;
begin
  result := FpropertyValues[index];
end;

procedure Tmplayer.Setoverlaycolor(const Value: Tcolor);
begin
  if Value <> Foverlaycolor  then begin
      Foverlaycolor := Value;
      CheckRestartNeeded;
  end;
end;
procedure Tmplayer.Setvideoout(const Value: string);
begin
if Value <> Fvideoout then begin
      Fvideoout := Value;
      CheckRestartNeeded;
  end;
end;
procedure Tmplayer.Setvideoeq(const Value: string);
begin
if Value <> Fvideoeq then begin
      Fvideoeq := Value;
      CheckRestartNeeded;
  end;
end;

procedure Tmplayer.SetDirectRender(const Value: boolean);
begin
  if Value <> FDirectRender then begin
      FDirectRender := Value;
      CheckRestartNeeded;
  end;
end;
procedure Tmplayer.SetDoubleBuffer(const Value: boolean);
begin
  if Value <> FDoubleBuffer then begin
      FDoubleBuffer := Value;
      CheckRestartNeeded;
  end;
end;
procedure Tmplayer.SetDrawSlices(const Value: boolean);
begin
  if Value <> FDrawSlices then begin
      FDrawSlices := Value;
      CheckRestartNeeded;
  end;
end;

procedure Tmplayer.SetTryScaler(const Value: boolean);
begin
  if Value <> FTryScaler then begin
      FTryScaler := Value;
      CheckRestartNeeded;
  end;
end;
procedure Tmplayer.SetVideoScaler(const Value: integer);
begin
  if Value <> FVideoScaler then begin
      FVideoScaler := Value;
      CheckRestartNeeded;
  end;
end;

procedure Tmplayer.SetpostProc(const Value: integer);
begin
  if Value <> FpostProc then begin
       FpostProc:= Value;
      CheckRestartNeeded;
  end;
end;
procedure Tmplayer.SetDeinterlace(const Value: integer);
var actvalue, newvalue : integer;
begin
  actvalue := DeinterlaceCmd(FDeinterlace,FDeinterlaceAlg, FDeinterlaceDvd);
  newvalue := DeinterlaceCmd(value,FDeinterlaceAlg,FDeinterlaceDvd);
  FDeinterlace := Value;
  if actvalue <> newvalue then
      CheckRestartNeeded;
end;
procedure Tmplayer.SetDeinterlaceAlg(const Value: integer);
var actvalue, newvalue : integer;
begin
  actvalue := DeinterlaceCmd(FDeinterlace,FDeinterlaceAlg,FDeinterlaceDvd);
  newvalue := DeinterlaceCmd(FDeinterlace,value,FDeinterlaceDvd);
  FDeinterlaceAlg := Value;
  if actvalue <> newvalue then
      CheckRestartNeeded;
end;
procedure Tmplayer.SetDeinterlaceDVD(const Value: boolean);
var actvalue, newvalue : integer;
begin
  actvalue := DeinterlaceCmd(FDeinterlace,FDeinterlaceAlg,FDeinterlaceDvd);
  newvalue := DeinterlaceCmd(FDeinterlace,FDeinterlaceAlg,Value);
  FDeinterlaceDVD := Value;
  if actvalue <> newvalue then
      CheckRestartNeeded;
end;

procedure Tmplayer.SetAspect(const Value: integer);
begin
  if FAspect <> Value then begin
    FAspect := Value;
    if aspectMsgOk then
      SetAndSendAspectfromPreset;
  end;
end;
procedure Tmplayer.SetAspectFactor(const Value: single);
begin
  if FAspectFactor <> value then begin
    FAspectFactor := Value;
    if aspectMsgOk then
      SetAndSendAspectfromPreset
  end;
end;

procedure Tmplayer.SetSubAutoLoad(const Value: Boolean);
begin
  if FSubAutoLoad <> value then begin
    FSubAutoLoad := Value;
    CheckRestartNeededByFonts;
  end;
end;

procedure Tmplayer.SetSubAss(const Value: Boolean);
begin
  if FSubAss <> Value then begin
    FSubAss := Value;
    CheckRestartNeededByFonts;
  end;
end;

procedure Tmplayer.SetSubAssBorderColor(const Value: tagRGBQUAD);
begin
  if LongInt(FSubAssBorderColor) <> LongInt(Value) then begin
    FSubAssBorderColor := Value;
    if FSubAss then
      CheckRestartNeededByFonts;
  end;
end;

procedure Tmplayer.SetSubAssColor(const Value: tagRGBQUAD);
begin
  if LongInt(FSubAssColor) <> LongInt(Value) then begin
    FSubAssColor := Value;
    if FSubAss then
      CheckRestartNeededByFonts;
  end;
end;

procedure Tmplayer.SetSubBgColor(const Value: tagRGBQUAD);
begin
  if LongInt(FSubBgColor) <> LongInt(Value) then begin
    FSubBgColor := Value;
    CheckRestartNeededByFonts;
  end;
end;

procedure Tmplayer.SetAudioOut(const Value: integer);
begin
  if Value <> FAudioOut then begin
      FAudioOut := Value;
      CheckRestartNeeded;
  end;
end;
procedure Tmplayer.SetAudioDev(const Value: integer);
begin
  if Value <> FAudioDev  then begin
      FAudioDev := Value;
      CheckRestartNeeded;
  end;
end;
procedure Tmplayer.SetAudioFilterChannels(const Value: string);
begin
  if value <>  FAudioFilterChannels then begin
    FAudioFilterChannels := value;
    CheckRestartNeeded;
  end;
end;
procedure Tmplayer.SetUseVolCmd(const Value: boolean);
begin
  if Value <> FUseVolCmd then begin
      FUseVolCmd := Value;
      CheckRestartNeeded;
  end;
end;
procedure Tmplayer.SetSoftVol(const Value: boolean);
begin
  if Value <> FSoftVol then begin
    FSoftVol := Value;
    if (not FSoftVol) and (FVolume > 100) then FVolume := 100;
    CheckRestartNeeded;
  end;
end;
procedure Tmplayer.SetAudioDecodeChannels(const Value: integer);
begin
  if value <>  FAudioDecodeChannels then begin
    FAudioDecodeChannels := value;
    CheckRestartNeeded;
  end;
end;
procedure Tmplayer.SetAc3Comp(const Value: integer);
begin
  if Value <> FAc3Comp then begin
    FAc3Comp:= Value;
    CheckRestartNeeded;
  end;
end;
procedure Tmplayer.SetUseliba52(const Value: boolean);
begin
  if Value <> FUseliba52 then begin
    FUseliba52 := Value;
    CheckRestartNeeded;
  end;
end;

procedure Tmplayer.SetUseDvdNav(const Value: boolean);
begin
  if value <> FuseDvdNav  then begin
    FUseDvdNav := Value;
    if Streaminfo.IsDvd then begin
      FirstOpen := true;
      CheckRestartNeeded;
    end;
  end;
end;

procedure Tmplayer.SetSpeed(const Value : real);
begin
  Fspeed := Value;
  if Fspeed > 100 then
    Fspeed := 100;
  if Fspeed < 0.01 then
    Fspeed := 0.01;
  sendSpeedCommand(Fspeed,0)
end;

procedure Tmplayer.SetVolume(const Value: integer);
begin
  FVolume := Value;

  if FVolume < 0 then FVolume := 0;
  if (not FSoftVol) and (FVolume > 100) then FVolume := 100;
  if FVolume > 1000 then FVolume := 1000;

  if Fmute then exit;

  sendVolumeCommandSoftVol(FVolume,0);
end;
procedure Tmplayer.SetMute(const Value: boolean);
begin
  FMute := Value;
  if FMute then
    SendVolumeMuteCommand()
  else
    Volume := FVolume;
end;
procedure Tmplayer.SetPause(const Value: boolean);
begin
  if Fstatus in [sPlaying, sPaused] then begin
    FPause := Value;
    SendPlayPause();
  end else
    if Fstatus in [sNone, sClosing, sError, sErrorRetry] then
      FPause := false
    else
      FPause := Value;
end;

procedure Tmplayer.SetOSDLevel(const Value: integer);
begin
  if Value<0 then FOSDLevel:=FOSDLevel+1
             else FOSDLevel:=Value;
  FOSDLevel:=FOSDLevel AND 3;
  SendProperty('osd', OSDLevel, -1);
end;

function Tmplayer.GetCachesize(index: integer): integer;
begin
  if (index>=low(FCachesize)) and (index <= high(FCachesize)) then
    Result := Fcachesize[index]
  else
    Result := 0;
end;

function Tmplayer.GetAudioID: integer;
begin
  Result := AudioIds.SelectedID;
end;
function Tmplayer.GetSubID: integer;
begin
  Result := SubIds.SelectedID;
end;
function Tmplayer.GetTitleID: integer;
begin
  Result := TitleIds.SelectedID;
end;
function Tmplayer.GetChapterID: integer;
begin
  Result := ChapterIds.SelectedID;
end;

procedure Tmplayer.SetAudioID(const Value: integer);
begin
  if Value <> AudioIds.SelectedID  then begin
    if not IsOpening then begin
      AudioIds.SetSelectedId(Value);
      if isAudioSwitchNoRestart then begin
        SendProperty('switch_audio', AudioIds.SelectedId , 1);
        if Fmute then begin
          Fmute := false;
          SetVolume(Fvolume); // resend volume;
          SetMute(true) // resend mute;
        end else
          SetVolume(Fvolume); // resend volume;
      end else
        CheckRestartNeeded;
    end;
  end;
end;
procedure Tmplayer.SetSubID(const Value: integer);
begin
    SetSubIDInt(Value,true);
end;
procedure Tmplayer.SetSubIDInt(const Value : integer; fromprop: boolean = false);
begin
  if Value <> SubIds.SelectedID  then begin
    if (not fromprop) or (not IsOpening) then begin
      SubIds.SetSelectedID(Value);
      if SubIds.SelectedId > -1 then begin
        SelectSubTrack(SubIds.SelectedId,true);
      end;
    end;
  end;
end;
procedure Tmplayer.SetTitleID(const Value: integer);
begin
  if Value <> TitleIds.SelectedID  then begin
    if TitleIds.Count > 0 then begin
      if not IsOpening then begin
        TitleIds.SetSelectedId(Value);
        FirstOpen := true;
        CheckRestartNeeded;
      end;
    end;
  end;
end;
procedure Tmplayer.SetChapterID(const Value: integer);
begin
  //if Value <> ChapterIds.SelectedID  then begin
    if ChapterIds.Count > 0 then begin
      if not IsOpening then begin
        ChapterIds.SetSelectedID(Value);
        if ChapterIds.Selected <> -1 then begin
          if FStatus = sPlaying then
            SendOsdShowCommand('CHAPTER ' + inttostr(ChapterIds.SelectedId),2500);
          seekto(ChapterIds.Items[ChapterIds.Selected].value[2], 2);
        end;
      end;
    end;
  //end;
end;

function Tmplayer.GetValidFileInfo : Boolean;
begin
  Result := (length(Mediafile)<>0) and Streaminfo.Valid;
end;

procedure Tmplayer.SetStatus(const Value: Tstatus);
var oldstatus : Tstatus;
begin
  if value <> Fstatus  then begin
    oldstatus := Fstatus;
    Fstatus := Value;
    FIsOpening := (Fstatus = sOpening) or (Fstatus = sPlayStarting);

    if Fstatus in [sNone, sClosing, sStopped, sError, sErrorRetry] then begin
      FPause := false;
      FFileLoaded := '';
    end;
    //Self.DoOnlog('---Status ------ ' + IntToStr(ord(Fstatus)),True);
    if assigned(FOnStatusChange) then
      FOnStatusChange(self,oldstatus,Fstatus);
  end;
end;
procedure Tmplayer.SetWindowHandle(const Value: cardinal);begin
  FWindowHandle := Value;
end;

procedure Tmplayer.SetOnlog(const Value: TNotifyEventLog);begin
  FOnlog := Value;
end;
procedure Tmplayer.SetOnlogClear(const Value: TNotifyEvent);begin
  FOnlogClear := Value;
end;
procedure Tmplayer.SetOnStatusChange(const Value: TNotifyEventStatusChange);begin
  FOnstatusChange := value;
end;
procedure Tmplayer.SetOnsubAdded(const Value: TNotifyEventItemChange);
begin
  FOnsubAdded := value;
end;
procedure Tmplayer.SetOnSubChange(const Value: TNotifyEventItemChange);
begin
  FOnsubChange := value;
end;

procedure Tmplayer.SetOnOverlayChange(const Value: TNOtifyEventOverlayChange);begin
  FOnOverlayChange := value;
end;
procedure Tmplayer.SetOnVideoSizeChanged(const Value: TNotifyEvent);begin
  FOnVideoSizeChanged := Value;
end;

procedure Tmplayer.SetOnPercentPosition(const Value: TNotifyEvent);begin
  FOnPercentPosition := Value;
end;
procedure Tmplayer.SetOnProgress(const Value: TNotifyEventProgress);
begin
  FOnProgress := Value;
end;
procedure Tmplayer.SetOnSecondPosition(const Value: TNotifyEvent);begin
  FOnSecondPosition := Value;
end;
procedure Tmplayer.SetOnAudioChange(const Value: TNotifyEventItemChange);
begin
  FOnAudioChange := Value;
end;
procedure Tmplayer.SetOnPropertysRead(const Value: TNotifyEvent);
begin
  FOnPropertysRead := Value;
end;
procedure Tmplayer.SetOnLoadNextFile(const Value: TNotifyEventLoadNextFile);
begin
  FOnLoadNextFile := Value;
end;
procedure Tmplayer.SetOnFileLoaded(const Value: TNotifyEventFileLoaded);
begin
  FOnFileLoaded := Value;
end;

end.
