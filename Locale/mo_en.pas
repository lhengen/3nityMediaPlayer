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

unit mo_en;
interface
implementation
uses Windows,Locale;

procedure Activate;
begin
  with LOCstr do begin
    Title:='3nity Media Player';
      Status_Opening:='Opening ...';						// 'Opening ...';
      Status_Closing:='Closing ...';						// 'Closing ...';
      Status_Playing:='Playing';						// 'Playing';
      Status_Paused:='Paused';							// 'Paused';
      Status_Stopped:='Stopped';						// 'Stopped';
      Status_Error:='Unable to play media (Click for more info)';		// 'Unable to play media (Click for more info)';	

    FullscreenControls:='Show fullscreen controls';				// 'Show fullscreen controls';
    OSD:='OSD mode';								// 'OSD mode';
      NoOSD:='No OSD';								// 'No OSD';
      DefaultOSD:='Default OSD';						// 'Default OSD';	
      TimeOSD:='Show time';							// 'Show time';
      FullOSD:='Show total time';						// 'Show total time';
    Escape:='Press Escape to exit fullscreen mode.';				// 'Press Escape to exit fullscreen mode.';
    Filemenu:='&File';								// '&File';
      OpenFile:='Play file ...';						// 'Play file ...';
      OpenURL:='Play URL ...';							// 'Play URL ...';
        OpenURL_Caption:='Play URL';						// 'Play URL';
        OpenURL_Prompt:='Which URL do you want to play?';			// 'Which URL do you want to play?';
      OpenDrive:='Play CD/DVD';							// 'Play CD/DVD';
      InternetRadios:='Internet radios';
      OpenTV := 'Open TV/capture card';
      Close:='Close';
      Quit:='Quit';
    View:='&View';
      SizeAny:='Custom size';
      Size50:='Half size';
      Size100:='Original size';
      Size200:='Double size';
      VideoInside:='Don''t crop video';
      Fullscreen:='Fullscreen';
      AudioEqu:='Equalizer';
      Compact:='Compact mode';
      TogOSD:='Toggle OSD';
      OnTop:='Always on top';
      Vis:='Visualization';
      VisEnable:='Show visualization';
      VisDirectRender:='Direct rendering';
    Seek:='&Play';
      Play:='Play';
      Pause:='Pause';
      Stop:='Stop';
      Prev:='Previous title'^I'Ctrl Left';
      Next:='Next title'^I'Ctrl Right';
      ShowPlaylist:='Playlist ...';
      Mute:='Mute';
      SeekF10:='Forward 10 seconds'^I'Right';
      SeekR10:='Rewind 10 seconds'^I'Left';
      SeekF60:='Forward 1 minute'^I'Up';
      SeekR60:='Rewind 1 minute'^I'Down';
      SeekF600:='Forward 10 minutes'^I'PgUp';
      SeekR600:='Rewind 10 minutes'^I'PgDn';
    Navigation:='&Navigation';
      Menu := 'Menu';
      Titles := 'Titles';
      Chapters:= 'Chapters';
    Extra:='&Options';
      Audio:='Audio track';
      Subtitle:='Subtitles track';
        NoSubtitle := 'No subtitles';
      AddSubtitle := 'Load subtitles...';

      Aspect:='Aspect ratio';
        AspectAuto:='Autodetect';
        Aspect43:='Force 4:3';
        Aspect169:='Force 16:9';
        Aspect235:='Force 2.35:1';
      DeinterlaceAlg:='Deinterlace algorithm';
        DeinterlaceBlend := 'Blend';
        DeinterlaceSimple := 'Simple';
        DeinterlaceAdaptative := 'Adaptive';
        DeinterlaceDoubleRate := 'Double rate';
      Deinterlace:='Deinterlace';

      Off := 'Off';
      On:='On';
      Auto:='Auto';

      Settings := 'Video adjustments ...';
      Options:='Settings ...';
      Language:='Language';
      StreamInfo:='Show file information ...';
      ShowOutput:='Show MPlayer output ...';
    Help:='&Help';
      KeyHelp:='Keyboard help ...';
      About := 'About ...';


    HelpFormCaption:='Keyboard help';
    HelpFormHelpText:=
'Navigation keys:'^M^J+
'Space'^I'Play/Pause'^M^J+
'Right'^I'Forward 10 seconds'^M^J+
'Left'^I'Rewind 10 seconds'^M^J+
'Up'^I'Forward 1 minute'^M^J+
'Down'^I'Rewind 1 minute'^M^J+
'PgUp'^I'Forward 10 minutes'^M^J+
'PgDn'^I'Rewind 10 minutes'^M^J+
^M+^J+
'Other keys:'^M^J+
'O'^I'Toggle OSD'^M^J+
'F'^I'Toggle fullscreen'^M^J+
'C'^I'Toggle compact mode'^M^J+
'T'^I'Toggle always on top'^M^J+
'Q'^I'Quit immediately'^M^J+
'9/0'^I'Adjust volume'^M^J+
'-/+'^I'Adjust audio/video sync'^M^J+
'1/2'^I'Adjust brightness'^M^J+
'3/4'^I'Adjust contrast'^M^J+
'5/6'^I'Adjust hue'^M^J+
'7/8'^I'Adjust saturation'^M^J+
'M'^I'Mute'^M^J+
'//*'^I'volume'^M^J+
'D'^I'frame_drop'^M^J+
'C'^I'Mode Compact'^M^J+
'T'^I'Always On Top'^M^J+
//'s'^I'screenshot'^M^J+
'L'^I'ShowPlaylist'^M^J+
'RETURN'^I'Play'^M^J+
'P'^I'Pause'^M^J+
'TAB'^I'Fullscreen Controls'^M^J+
'NUMPAD9'^I'Zoom +'^M^J+
'NUMPAD5'^I'Zoom Reset'^M^J+
'NUMPAD1'^I'Zoom -'^M^J+
'NUMPAD6'^I'inc Aspect'^M^J+
'NUMPAD8'^I'Reset Aspect'^M^J+
'NUMPAD4'^I'Dec Aspect'^M^J+
'NUMPAD7'^I'Crop Video'^M^J+
'V'^I^I'subtitles visibility'^M^J+
'CTRL+0'^I^I'Reset Speed'^M^J+
'CTRL+/'^I^I'Speed -'^M^J+
'CTRL+*'^I^I'Speed +'^M^J+
'CTRL+O'^I^I'OpenFile'^M^J+
'CTRL+L'^I^I'Open URL'^M^J+
'CTRL+W'^I^I'Close'^M^J+
'CTRL+LEFT'^I'Play previous track'^M^J+
'CTRL+RIGHT'^I'Play next track'^M^J+
'Alt+0'^I^I'Custom size'^M^J+
'Alt+1'^I^I'Half Size'^M^J+
'Alt+2'^I^I'Original size'^M^J+
'Alt+3'^I^I'Double size'^M^J+
'Alt+F4'^I^I'Close Program'^M^J+
'Alt+Return'^I'Fullscreen'^M^J+
'MEDIA_STOP'^I^I'Stop Playing'^M^J+
'MEDIA_PREV_TRACK'^I'Play previous track'^M^J+
'MEDIA_NEXT_TRACK'^I'Play next track'
  ;
    HelpFormClose:='Close';

    //log form
    LogFormCaption:='MPlayer output';
    LogFormClose:='Close';

    //about form
    AboutFormCaption := 'About 3nity Media Player';
    AboutFormClose := 'Close';
    AboutVersionMPUI := '3nity Media Player version:';
    AboutVersionMplayer := 'MPlayer version:';

    //settings form
    SettingsformCaption := 'Video adjustments';
    Brightness := 'Brightness';
    Contrast := 'Contrast';
    Hue := 'Hue';
    Saturation := 'Saturation';
    Gamma := 'Gamma';
    SubScale := 'Subtitles size';
    ResetSetting := 'Reset';
    MResetSetting := 'Master reset';

    //options form
    FullScreenMonitor := 'Fullscreen monitor';
    AutoLocale:='(Auto-select)';

    OptionsFormCaption:='Settings';
    OptionsFormOK:='OK';
    OptionsFormApply:='Apply';

    OptionsFormAssociate:='Associate';
    OptionsFormSelectAll:='Select All';
    OptionsFormSelectNone:='None';
    OptionsFormSave:='Save';
    OptionsFormClose:='Close';
    OptionsFormHelp:='Help';
    OptionsFormParams:='Additional MPlayer parameters:';

    OptionsFormIndex:='Rebuild file index if necessary';
    OptionsFormPriorityBoost:='Run with higher priority';

    Autosync := 'Autosync factor';
    AVsyncperframe := 'A-V sync per frame (us.)';

    OptionsFormAudioOut:='Sound output driver';
    AudioOutNoDecode:='(don''t decode sound)';
    AudioOutNoOut:='(don''t play sound)';
    OptionsFormAudioDev:='DirectSound output device';
    OptionsFormAudioFilterChannels := 'Channel filtering and routing';
    OptionsFormSoftVol:='Software volume control / Volume boost';
    OptionsFormUseVolcmd := 'Use volume command line option';
    OptionsFormAudioDecodeChannels := 'Max. num. of channels to decode';
    OptionsFormAc3Comp := 'AC3 compression level';
    OptionsFormUseliba52 := 'Use liba52 library';

    OptionsFormVideoOut := 'Video output driver';
    VideoOutUser := 'Other:';
    OptionsFormOverlay:= 'Overlay color';
    ForceEvenWidth := 'Force even width';
    DirectRender := 'Direct rendering';
    DoubleBuffer := 'Double buffering';
    DrawSlices := 'Draw using slices';

    OptionsFormVideoeq  := 'Software video equalizer';
    VideoeqOff  := 'Off';
    VideoScaler := 'Software video scaler';
    TryScaler := 'Try scaler on error';

    OptionsFormPostproc:='Postprocessing';
    PostprocOff:='Off';
    PostprocAuto:='Automatic';
    PostprocMax:='Maximum quality';

    OptionsFormGeneral := 'General';
    OptionsFormAudio := 'Audio';
    OptionsFormVideo := 'Video';
    OptionsFormCaching := 'Caching';
    OptionsFormOSDSub := 'OSD and subs';

    MediaDefault := 'Default';
    MediaFixed := 'Fixed disk';
    MediaRamdisk := 'RAM disk';
    MediaCdrom := 'CD-ROM / DVD-ROM';
    MediaRemovable := 'Removable device';
    mediaNetwork := 'Local network';
    MediaInternet := 'Internet';
    MediaDvd := 'DVD playback';

    FontPath := 'Font';
    FontEncoding := 'Character encoding';
    FontEncodings[0] := 'Default encoding';
    FontEncodings[1] := 'Unicode';
    FontEncodings[2] := 'Western European Languages (ISO-8859-1)';
    FontEncodings[3] := 'Western European Languages with Euro (ISO-8859-15)';
    FontEncodings[4] := 'Slavic/Central European Languages (ISO-8859-2)';
    FontEncodings[5] := 'Esperanto, Galician, Maltese, Turkish (ISO-8859-3)';
    FontEncodings[6] := 'Old Baltic charset (ISO-8859-4)';
    FontEncodings[7] := 'Cyrillic (ISO-8859-5)';
    FontEncodings[8] := 'Arabic (ISO-8859-6)';
    FontEncodings[9] := 'Modern Greek (ISO-8859-7)';
    FontEncodings[10] := 'Turkish (ISO-8859-9)';
    FontEncodings[11] := 'Baltic (ISO-8859-13)';
    FontEncodings[12] := 'Celtic (ISO-8859-14)';
    FontEncodings[13] := 'Hebrew charsets (ISO-8859-8)';
    FontEncodings[14] := 'Russian (KOI8-R)';
    FontEncodings[15] := 'Ukrainian, Belarusian (KOI8-U/RU)';
    FontEncodings[16] := 'Simplified Chinese charset (CP936)';
    FontEncodings[17] := 'Traditional Chinese charset (BIG5)';
    FontEncodings[18] := 'Japanese charsets (SHIFT-JIS)';
    FontEncodings[19] := 'Korean charset (CP949)';
    FontEncodings[20] := 'Thai charset (CP874)';
    FontEncodings[21] := 'Cyrillic Windows (CP1251)';
    FontEncodings[22] := 'Slavic/Central European Windows (CP1250)';

    FontConfig := 'Fontconfig (font scanning)';
    SubAss := 'Use SSA/ASS';
    SubAutoLoad := 'Load external subtitle files';

    SubAssBorderColor := 'Text border color';
    SubAssColor := 'Text color';
    SubBgColor := 'Text background color';

    UseDvdNav := 'Enable DVD menus ';
    DeinterlaceDVD := 'Always deinterlace';

    //playlist form
    PlaylistFormCaption:='Playlist';
    PlaylistFormPlay:='Play';
    PlaylistFormAdd:='Add ...';
    PlaylistFormMoveUp:='Move up';
    PlaylistFormMoveDown:='Move down';
    PlaylistFormDelete:='Remove';
    PlaylistFormShuffle:='Shuffle';
    PlaylistFormLoop:='Repeat';
    PlaylistFormSave:='Save ...';
    PlaylistFormClose:='Close';

    InfoFormCaption:='File information';
    InfoFormClose:='Close';
    InfoFormCopy := 'Copy';
    NoInfo:='No file information is available at the moment.';
    InfoFileFormat:='Format';
    InfoPlaybackTime:='Duration';
    InfoTags:='Clip metadata';
    InfoVideo:='Video track';
    InfoAudio:='Audio track';
    InfoDecoder:='Decoder';
    InfoCodec:='Codec';
    InfoBitrate:='Bitrate';
    InfoVideoSize:='Dimensions';
    InfoVideoFPS:='Frame rate';
    InfoVideoAspect:='Aspect ratio';
    InfoAudioRate:='Sample rate';
    InfoAudioChannels:='Channels';
    InfoInterlace:='Frame';
    InfoVideoInt := 'Interlaced';
    InfoVideoPro := 'Progressive';
    InfoTrack := 'Track';
    InfoFilesize := 'Filesize';
    InfoSub := 'Subtitles';
    InfoFormCopyAll := 'Copy All';
  end
end;

begin
  RegisterLocale('English',Activate,LANG_ENGLISH,ANSI_CHARSET);
end.
