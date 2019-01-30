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
{Special Note for Developers:

    This code can be compiled using Embarcadero Delphi XE2 -> to Delphi 10.3 Rio( i'm using XE7 )
    You will need to install Alphaskin and OmniThreadLibrary components.
    For special questions or if you want to hire a delphi developer you can contact me:  nicolas.deoux@gmail.com
}

unit mo_es;
interface
implementation
uses Windows,Locale;

procedure Activate;
begin
  with LOCstr do begin
    Title:='3nity Media Player';
      Status_Opening:='Abriendo ...';
      Status_Closing:='Cerrando ...';
      Status_Playing:='Reproduciendo';
      Status_Paused:='Pausa';
      Status_Stopped:='Detenido';
      Status_Error:='Imposible leer medio (Click para m�s informaci�n)';

    FullscreenControls:='Mostrar controles pantalla completa';
    OSD:='Establecer modo OSD';
      NoOSD:='Sin OSD';
      DefaultOSD:='OSD predefinido';
      TimeOSD:='Mostrar tiempo';
      FullOSD:='Mostrar tiempo total';
    Escape:='Presione Esc para salir del modo pantalla completa';
    Filemenu:='&Archivo';
      OpenFile:='Reproducir archivo ...';
      OpenURL:='Reproducir URL ...';
        OpenURL_Caption:='Reproducir URL';
        OpenURL_Prompt:='�Cu�l es la URL a reproducir?';
      OpenDrive:='Reproducir CD/DVD';
      OpenTV := 'Abrir TV/tarjeta capturadora';
      Close:='Cerrar';
      Quit:='Salir';
    View:='&Ver';
      SizeAny:='Tama�o personalizado';
      Size50:='Mitad del tama�o';
      Size100:='Tama�o original';
      Size200:='Doble del tama�o';
      VideoInside:='No recortar video';
      Fullscreen:='Pantalla completa';
      AudioEqu:='ecualizador';   //ecualizador de audio
      Compact:=   'Modo Compacto';
      TogOSD:=    'Cambiar OSD';
      OnTop:=     'Siempre visible';
      Vis:='Visualizaci�n';
      VisEnable:='Mostrar visualizaci�n';
      VisDirectRender:='Renderizado directo';
    Seek:='&Reproducci�n';
      Play:='Reproducir';
      Pause:='Pausar';
      Prev:='T�tulo anterior'^I'Ctrl Izquierda';
      Next:='T�tulo siguiente'^I'Ctrl Derecha';
      ShowPlaylist:='Lista de reproducci�n ...';
      Mute:='Mute';
      SeekF10:='Avanzar 10 segundos'^I'Derecha';
      SeekR10:='Retroceder 10 segundos'^I'Izquierda';
      SeekF60:='Avanzar 1 minuto'^I'Arriba';
      SeekR60:='Retroceder 1 minuto'^I'Abajo';
      SeekF600:='Avanzar 10 minutos'^I'ReP�g';
      SeekR600:='Retroceder 10 minutos'^I'AvP�g';
    Navigation:='&Navegaci�n';
      Menu := 'Men�';
      Titles := 'T�tulos';
      Chapters:= 'Cap�tulos';
    Extra:='&Preferencias';
      Audio:='Pista de audio';
      Subtitle:='Pista de subt�tulo';
        NoSubtitle := 'Sin subt�tulos';
      AddSubtitle := 'Cargar subt�tulos...';

      Aspect:='Relaci�n de aspecto';
        AspectAuto := 'Autodetectar';
        Aspect43 := 'Forzar 4:3';
        Aspect169 := 'Forzar 16:9';
        Aspect235 := 'Forzar 2.35:1';
      DeinterlaceAlg:='Algoritmo desentrelazado';
        DeinterlaceBlend := 'Fundido';
        DeinterlaceSimple := 'Simple';
        DeinterlaceAdaptative := 'Adaptativo';
        DeinterlaceDoubleRate := 'Frecuencia doble';
      Deinterlace:='Desentrelazado';

      Off := 'Desactivado';
      On := 'Activado';
      Auto := 'Autom�tico';

      Settings := 'Ajustes ...';
      Options:='Preferencias ...';
      Language:='Idioma';
      StreamInfo:='Informaci�n del archivo ...';
      ShowOutput:='Mostrar mensajes de MPlayer';
    Help:='A&yuda';
      KeyHelp:='Ayuda de teclado ...';
      About:='Acerca de ...';
   

  HelpFormCaption:='Ayuda de teclado';
  HelpFormHelpText:=
'Teclas de navegaci�n:'^M^J+
'Espacio'^I'Reproducir/Pausar'^M^J+
'Derecha'^I'Avanzar 10 segundos'^M^J+
'Izquierda'^I'Retroceder 10 segundos'^M^J+
'Arriba'^I'Avanzar 1 minuto'^M^J+
'Abajo'^I'Retroceder 1 minuto'^M^J+
'ReP�g'^I'Avanzar 10 minutos'^M^J+
'AvP�g'^I'Retroceder 10 minutos'^M^J+
^M+^J+
'Otras teclas:'^M^J+
'O'^I'Cambiar OSD'^M^J+
'F'^I'Cambiar pantalla completa'^M^J+
'Q'^I'Salir inmediatamente'^M^J+
'9/0'^I'Ajustar volumen'^M^J+
'-/+'^I'Ajustar sincronizaci�n de audio/v�deo'^M^J+
'1/2'^I'Ajustar brillo'^M^J+
'3/4'^I'Ajustar contraste'^M^J+
'5/6'^I'Ajustar tinta'^M^J+
'7/8'^I'Ajustar saturaci�n'^M^J+
'M'^I'Mute'^M^J+
'//*'^I'Ajustar volumen'^M^J+
'D'^I'frame_drop'^M^J+
'C'^I'Modo Compacto'^M^J+
'T'^I'Siempre visible'^M^J+
//'s'^I'screenshot'^M^J+
'L'^I'Lista de reproducci�n'^M^J+
'RETURN'^I'Reproducir'^M^J+
'P'^I'Pausar'^M^J+
'TAB'^I'Mostrar controles pantalla completa'^M^J+
'NUMPAD9'^I'Zoom +'^M^J+
'NUMPAD5'^I'Zoom Reset'^M^J+
'NUMPAD1'^I'Zoom -'^M^J+
'NUMPAD6'^I'inc Aspect'^M^J+
'NUMPAD8'^I'Reset Aspect'^M^J+
'NUMPAD4'^I'Dec Aspect'^M^J+
'NUMPAD7'^I'No recortar video'^M^J+
'V'^I^I'Pista de subt�tulo'^M^J+
'CTRL+0'^I^I'Reset Speed'^M^J+
'CTRL+/'^I^I'Speed -'^M^J+
'CTRL+*'^I^I'Speed +'^M^J+
'CTRL+O'^I^I'Reproducir archivo'^M^J+
'CTRL+L'^I^I'Reproducir URL'^M^J+
'CTRL+W'^I^I'Cerrar'^M^J+
'CTRL+LEFT'^I'T�tulo anterior'^M^J+
'CTRL+RIGHT'^I'T�tulo siguiente'^M^J+
'Alt+0'^I^I'Tama�o personalizado'^M^J+
'Alt+1'^I^I'Mitad del tama�o'^M^J+
'Alt+2'^I^I'Tama�o original'^M^J+
'Alt+3'^I^I'Doble del tama�o'^M^J+
'Alt+F4'^I^I'Close Program'^M^J+
'Alt+Return'^I'Cambiar pantalla completa'^M^J+
'CTRL+LEFT'^I'T�tulo anterior'^M^J+
'CTRL+RIGHT'^I'T�tulo siguiente'^M^J+
'MEDIA_STOP'^I^I'Stop '^M^J+
'MEDIA_PREV_TRACK'^I'T�tulo anterior'^M^J+
'MEDIA_NEXT_TRACK'^I'T�tulo siguiente'
  ;
  HelpFormClose:='Cerrar';

  //log form
  LogFormCaption:='Mensajes de MPlayer';
  LogFormClose:='Cerrar';

  //about form
  AboutFormCaption:='Acerca de 3nity Media Player';
  AboutFormClose:='Cerrar';
  AboutVersionMPUI:='Versi�n de 3nity Media Player:';
  AboutVersionMplayer:='Versi�n de MPlayer:';

  //settings form
  SettingsformCaption := 'Ajustes';
    Brightness := 'Brillo';
    Contrast := 'Contraste';
    Hue := 'Tono';
    Saturation := 'Saturaci�n';
    Gamma := 'Gamma';
    SubScale := 'Tama�o sub.';
    ResetSetting := 'Restablecer';
    MResetSetting := 'Restablecer todo';

  //options form
    FullScreenMonitor := 'Monitor pantalla completa';
    AutoLocale:='(Auto-selecci�n)';

    OptionsFormCaption:='Preferencias';
    OptionsFormOK:='Aceptar';
    OptionsFormApply:='Aplicar';

        OptionsFormAssociate:='Associate';
    OptionsFormSelectAll:='Select All';
    OptionsFormSelectNone:='None';


    OptionsFormSave:='Guardar';
    OptionsFormClose:='Cerrar';
    OptionsFormHelp:='Ayuda';
    OptionsFormParams:='Par�metros adicionales de MPlayer:';

    OptionsFormIndex:='Reconstruir �ndice del archivo si es necesario';
    OptionsFormPriorityBoost:='Ejecutar con prioridad alta';

    Autosync := 'Factor auto-sincronizaci�n';
    AVsyncperframe := 'Sincronizaci�n A-V por cuadro (us.)';

    OptionsFormAudioOut:='Controlador de salida de audio';
      AudioOutNoDecode:='(no decodificar sonido)';
      AudioOutNoOut:='(no reproducir sonido)';
    OptionsFormAudioDev:='Dispositivo de salida DirectSound';
    OptionsFormAudioFilterChannels := 'Filtrado y redirecci�n de canales';
    OptionsFormSoftVol:='Control volumen software / Amplificaci�n sonido';
    OptionsFormUseVolcmd := 'Usar opci�n volumen en linea de comandos';
    OptionsFormAudioDecodeChannels := 'M�x. de canales a descodificar';
    OptionsFormAc3Comp := 'Nivel de compresi�n AC3';
    OptionsFormUseliba52 := 'Usar librer�a liba52';

    OptionsFormVideoOut := 'Controlador de salida de v�deo';
      VideoOutUser := 'Otro:';
    OptionsFormOverlay:= 'Color para superposici�n';
    ForceEvenWidth := 'Forzar ancho par';
    DirectRender := 'Renderizado directo';
    DoubleBuffer := 'Doble b�fer';
    DrawSlices := 'Dibujo incremental';

    OptionsFormVideoeq  := 'Equalizador de video software';
      VideoeqOff  := 'Desactivado';
    VideoScaler := 'Escalado por software';
    TryScaler := 'Probar escalado si error';

    OptionsFormPostproc:='Post-procesado';
      PostprocOff:='Desactivado';
      PostprocAuto:='Autom�tico';
      PostprocMax:='M�xima calidad';

    OptionsFormGeneral := 'General';
    OptionsFormAudio := 'Audio';
    OptionsFormVideo := 'Video';
    OptionsFormCaching := 'Cache';
    OptionsFormOSDSub := 'OSD y subs';

    MediaDefault := 'Por defecto';
    MediaFixed := 'Disco fijo';
    MediaRamdisk := 'Unidad RAM';
    MediaCdrom := 'CD-ROM / DVD-ROM';
    MediaRemovable := 'Medio Extraible';
    mediaNetwork := 'Red local';
    MediaInternet := 'Internet';
    MediaDvd := 'Reproducci�n DVD';

    FontPath := 'Fuente';
    FontEncoding := 'Codificaci�n de caracteres';    
    FontEncodings[0] := 'Codificaci�n por defecto';
    FontEncodings[1] := 'Unicode';
    FontEncodings[2] := 'Occidental (ISO-8859-1)';
    FontEncodings[3] := 'Occidental con euro (ISO-8859-15)';
    FontEncodings[4] := 'Eslavo/Centroeuropeo (ISO-8859-2)';
    FontEncodings[5] := 'Esperanto, Gallego, Malt�s, Turco (ISO-8859-3)';
    FontEncodings[6] := 'B�ltico (ISO-8859-4)';
    FontEncodings[7] := 'Cir�lico (ISO-8859-5)';
    FontEncodings[8] := '�rabe (ISO-8859-6)';
    FontEncodings[9] := 'Griego moderno (ISO-8859-7)';
    FontEncodings[10] := 'Turco (ISO-8859-9)';
    FontEncodings[11] := 'B�ltico (ISO-8859-13)';
    FontEncodings[12] := 'C�ltico (ISO-8859-14)';
    FontEncodings[13] := 'Hebreo (ISO-8859-8)';
    FontEncodings[14] := 'Ruso (KOI8-R)';
    FontEncodings[15] := 'Bieloruso (KOI8-U/RU)';
    FontEncodings[16] := 'Chino simplificado (CP936)';
    FontEncodings[17] := 'Chino tradicional (BIG5)';
    FontEncodings[18] := 'Japon�s(SHIFT-JIS)';
    FontEncodings[19] := 'Coreano (CP949)';
    FontEncodings[20] := 'Tailand�s (CP874)';
    FontEncodings[21] := 'Cir�lico (Windows) (CP1251)';
    FontEncodings[22] := 'Eslavo/Centroeuropeo (Windows) (CP1250)';

    FontConfig := 'Fontconfig (escanea fuentes)';
    SubAss := 'Usar SSA/ASS';
    SubAutoLoad := 'Cargar subt�tulos externos';

    SubAssBorderColor := 'Color del borde del texto';
    SubAssColor := 'Color del texto';
    SubBgColor := 'Color del fondo del texto';

    UseDvdNav := 'Activar soporte Men�s DVD (experimental)';
    DeinterlaceDVD := 'Desentrelazar siempre';

  //playlist form
  PlaylistFormCaption:='Lista de reproducci�n';
  PlaylistFormPlay:='Reproducir';
  PlaylistFormAdd:='Agregar ...';
  PlaylistFormMoveUp:='Mover arriba';
  PlaylistFormMoveDown:='Mover abajo';
  PlaylistFormDelete:='Borrar';
  PlaylistFormShuffle:='Aleatorio';
  PlaylistFormLoop:='Repetici�n';
  PlaylistFormSave:='Guardar ...';
  PlaylistFormClose:='Cerrar';

  InfoFormCaption:='Informaci�n del archivo';
  InfoFormClose:='Cerrar';
  InfoFormCopy := 'Copiar';
  NoInfo:='No hay informaci�n disponible.';
  InfoFileFormat:='Formato';
  InfoPlaybackTime:='Duracion';
  InfoTags:='Metadatos';
  InfoVideo:='Video';
  InfoAudio:='Audio';
  InfoDecoder:='Decodificador';
  InfoCodec:='Codec';
  InfoBitrate:='Tasa de bits';
  InfoVideoSize:='Tama�o';
  InfoVideoFPS:='Im�genes por seg.';
  InfoVideoAspect:='Relaci�n de asp.';
  InfoAudioRate:='Frec. de muestreo';
  InfoAudioChannels:='Canales';
  InfoInterlace:='Fotograma';
  InfoVideoInt := 'Entrelazado';
  InfoVideoPro := 'Progresivo';
  InfoTrack := 'Pista';
  InfoFilesize := 'Tama�o';
  InfoSub := 'Subt�tulos';
  end;
end;

begin
  RegisterLocale('Spanish - Espa�ol',Activate,LANG_SPANISH,DEFAULT_CHARSET);
end.
