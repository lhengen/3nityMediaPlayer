{

	3nity Media Player, an MPlayer frontend for Windows

	Copyright (C) 2010-2019 Nicolas DEOUX  < nicolas.deoux@gmail.com >
									<http://3nitysoftwares.com>

    Original source code 2008-2010 Visenri  <http://sourceforge.net/projects/mpui-ve/>
    Original source code (2005) by Martin J. Fiedler <martin.fiedler@gmx.net>>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
}
{   to compile:

    This code can be compiled using Embarcadero Delphi XE2 -> to Delphi 10.3 Rio( here using XE7  )
    You will need to install Alphaskin and OmniThreadLibrary components.
    For special questions or if you want to hire a delphi developer you can contact me:  nicolas.deoux@gmail.com
}

unit Locale;
interface
uses Graphics;

type proc=procedure;
     TLocale=record
               Name:WideString;
               Func:proc;
               LangID:integer;
               Charset:TFontCharset;
             end;
type Tlocalestrings= record
    Title,

    Status_Opening,
    Status_Closing,
    Status_Playing,
    Status_Paused,
    Status_Stopped,
    Status_Error,

    FullscreenControls,
    OSD,
      NoOSD,
      DefaultOSD,
      TimeOSD,
      FullOSD,
    Escape,
    Filemenu,
      OpenFile,
      OpenURL,
        OpenURL_Caption,
        OpenURL_Prompt,
      OpenDrive,
      OpenTV,
      InternetRadios,
      Close,
      Quit,
    View,
      SizeAny,
      Size50,
      Size100,
      Size200,
      VideoInside,
      Fullscreen,
      AudioEqu,
      Compact,
      TogOSD,
      OnTop,
      Vis,
      VisEnable,
      VisDirectRender,
    Seek,
      Play,
      Pause,
      Stop,
      Prev,
      Next,
      ShowPlaylist,
      Mute,
      SeekF10,
      SeekR10,
      SeekF60,
      SeekR60,
      SeekF600,
      SeekR600,
    Navigation,
      Menu,
      Titles,
      Chapters,
    Extra,
      Audio,
      Subtitle,
        NoSubtitle,
      AddSubtitle,
    Settings ,
      Aspect,
      DeinterlaceAlg,
      Deinterlace,
      Options,
      Language,
      StreamInfo,
      ShowOutput,
    Help,
      KeyHelp,
      About,
    

    InfoFormCaption,
    InfoFormClose,
    InfoFormCopy,
    InfoFormCopyAll,
    NoInfo,
    InfoFileFormat,
    InfoPlaybackTime,
    InfoTags,
    InfoVideo,
    InfoAudio,
    InfoDecoder,
    InfoCodec,
    InfoBitrate,
    InfoVideoSize,
    InfoVideoFPS,
    InfoVideoInt,
    InfoVideoPro,
    InfoVideoAspect,
    InfoAudioRate,
    InfoAudioChannels,
    InfoInterlace,
    InfoTrack,
    InfoFilesize,
    InfoSub,

    AspectAuto,
    Aspect43,
    Aspect169,
    Aspect235,
    DeinterlaceBlend,
    DeinterlaceSimple,
    DeinterlaceAdaptative,
    DeinterlaceDoubleRate,

    ForceEvenWidth,
    DirectRender,
    DoubleBuffer,
    DrawSlices,

    TryScaler,
    VideoScaler,


    Off, On, Auto : Widestring;



    DeinterlaceAlgMap:array[0..3]of WideString;
    AspectMap:array[0..3]of WideString;

    Postproc: array[0..2]of WideString;

    AudioOut: array[0..1]of WideString;

    OffOnAuto : array[0..2] of WideString;

    FontEncodings : array[0..22] of WideString;




    //Log:
    LogFormCaption,
    LogFormClose : WideString;

    //about:
    AboutFormCaption,
    AboutFormClose,
    AboutVersionMPUI,
    AboutVersionMplayer : WideString;

    //help:
    HelpFormCaption,
    HelpFormHelpText,
    HelpFormClose : WideString;

    //settings
    SettingsformCaption: WideString;
    Brightness,
    Contrast,
    Hue,
    Saturation,
    Gamma,
    SubScale : WideString;

    ResetSetting,
    MResetSetting : WideString;


    //options form:
    OptionsFormCaption,
    OptionsFormOK,
    OptionsFormApply,
    //implémenté
    OptionsFormAssociate,
    OptionsFormSelectAll,
    OptionsFormSelectNone,

    OptionsFormSave,
    OptionsFormClose,
    OptionsFormAudioOut,
      AudioOutNoDecode,
      AudioOutNoOut,
    OptionsFormAudioDev,
    OptionsFormAudioFilterChannels,
    OptionsFormUseVolcmd ,
    OptionsFormAudioDecodeChannels,
    OptionsFormAc3Comp,
    OptionsFormUseliba52,
    OptionsFormPostproc,
      PostprocOff,
      PostprocAuto,
      PostprocMax,

    FullScreenMonitor,
    AutoLocale,
    OptionsFormIndex,
    Autosync,
    AVsyncperframe,
    OptionsFormSoftVol,
    OptionsFormOverlay,
    OptionsFormVideoOut ,
      VideoOutUser,
    OptionsFormVideoeq  ,
      VideoeqOff,

    OptionsFormPriorityBoost,
    OptionsFormParams,
    OptionsFormHelp : WideString;

    OptionsFormGeneral,
    OptionsFormAudio,
    OptionsFormVideo,
    OptionsFormCaching,
    OptionsFormOSDSub : WideString;

    MediaDefault,
    MediaFixed,
    MediaRamdisk,
    MediaCdrom,
    MediaRemovable,
    mediaNetwork,
    MediaInternet,
    MediaDvd : WideString;

    FontEncoding,
    FontPath,
    FontConfig,
    SubAss,
    SubAutoLoad,
    SubAssBorderColor,
    SubAssColor,
    SubBgColor : WideString;

    UseDvdNav,
    DeinterlaceDVD : WideString;

    //Playlist form:
    PlaylistFormCaption,
    PlaylistFormPlay,
    PlaylistFormAdd,
    PlaylistFormMoveUp,
    PlaylistFormMoveDown,
    PlaylistFormDelete,
    PlaylistFormShuffle,
    PlaylistFormLoop,
    PlaylistFormSave,
    PlaylistFormClose : WideString;
end;

var Locales:array of TLocale;
    CurrentLocale:integer;
    CurrentLocaleCharset : TFontCharset;

  LOCstr : Tlocalestrings;

const NoLocale=-1;
      AutoLocale=-1;

procedure RegisterLocale(const _Name:WideString; const _Func:proc; _LangID:integer; _Charset:TFontCharset);
procedure ActivateLocale(Index:integer);

implementation
uses Windows, Forms, FormLocal;

procedure RegisterLocale(const _Name:WideString; const _Func:proc; _LangID:integer; _Charset:TFontCharset);
begin
  SetLength(Locales,length(Locales)+1);
  with Locales[High(Locales)] do begin
    Name:=_Name;
    Func:=_Func;
    LangID:=_LangID;
    Charset:=_Charset;
  end;
end;

procedure ActivateLocale(Index:integer);
var i,WantedLangID:integer;
begin
  if Index=AutoLocale then begin
    WantedLangID:=GetUserDefaultLCID() AND 1023;
    Index:=0;
    for i:=Low(Locales) to High(Locales) do
      if Locales[i].LangID=WantedLangID then begin
        Index:=i;
        break;
      end;
  end;
  if (Index<Low(Locales)) OR (Index>High(Locales)) then exit;

  CurrentLocale:=Index;
  CurrentLocaleCharset := Locales[Index].Charset;
  Locales[Index].Func;


  LOCstr.AspectMap[0] := LOCstr.AspectAuto;
  LOCstr.AspectMap[1] := LOCstr.Aspect43;
  LOCstr.AspectMap[2] := LOCstr.Aspect169;
  LOCstr.AspectMap[3] := LOCstr.Aspect235;
  //LOCstr.AspectMap[4] := LOCstr.AspectUser;

  LOCstr.DeinterlaceAlgMap[0] := LOCstr.DeinterlaceBlend;
  LOCstr.DeinterlaceAlgMap[1] := LOCstr.DeinterlaceSimple;
  LOCstr.DeinterlaceAlgMap[2] := LOCstr.DeinterlaceAdaptative;
  LOCstr.DeinterlaceAlgMap[3] := LOCstr.DeinterlaceDoubleRate;


  LOCstr.Postproc[0] :=  LOCstr.PostprocOff;
  LOCstr.Postproc[1] :=  LOCstr.PostprocAuto;
  LOCstr.Postproc[2] :=  LOCstr.PostprocMax;

  LOCstr.AudioOut[0] :=  LOCstr.AudioOutNoDecode;
  LOCstr.AudioOut[1] :=  LOCstr.AudioOutNoOut;

  LOCstr.OffOnAuto[0] := LOCstr.Off;
  LOCstr.OffOnAuto[1] := LOCstr.On;
  LOCstr.OffOnAuto[2] := LOCstr.Auto;

  Application.Title:=LOCstr.Title;

  if Application.MainForm is TformLocal then
    begin
      (Application.MainForm as TFormlocal).DoLocalize;
    end;

  for i := 0 to Screen.FormCount - 1 do begin
    if Screen.forms[i] <> Application.MainForm then
      if Screen.Forms[i] is TformLocal then
        (Screen.Forms[i] as TFormlocal).NotifyLocalize;
  end;
end;

begin
  SetLength(Locales,0);
  CurrentLocale:=NoLocale;
end.
