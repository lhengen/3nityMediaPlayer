; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "3nity Media Player"
#define MyAppVersion "5.0.5"
#define MyAppPublisher "3nity Softwares"
#define MyAppURL "http://www.3nitysoftwares.com/"
#define MyAppExeName "3nity.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{D3D81DF1-2CD5-4501-9887-0FF48ACBD25F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
;OutputDir=CurrentDir\Output\
OutputBaseFilename=3nityMediaPlayer
Compression=lzma
SolidCompression=yes
ChangesAssociations=yes
WizardImageFile=embedded\WizardImage.bmp
WizardSmallImageFile=embedded\WizardSmallImage.bmp
;WizardImageFile=myimage.bmp
;WizardSmallImageFile=<chemin de l'image>
;WizardImageBackColor=clRed

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; 
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 0,6.1

[Files]
;Source: "..\Binaries\3nity.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Binaries\*"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Binaries\mplayer\*"; DestDir: "{app}\mplayer"; Flags: ignoreversion createallsubdirs recursesubdirs
;Source: "..\Binaries\codecs\*"; DestDir: "{app}\codecs"; Flags: ignoreversion createallsubdirs recursesubdirs
Source: "..\Binaries\fonts\*"; DestDir: "{app}\fonts"; Flags: ignoreversion createallsubdirs recursesubdirs
;Source: "..\Binaries\skins\*"; DestDir: "{app}\skins"; Flags: ignoreversion createallsubdirs recursesubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:ProgramOnTheWeb,{#MyAppName}}"; Filename: "{#MyAppURL}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
;Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}";Parameters: "/register"; Flags: nowait postinstall skipifsilent
Filename: "{app}\{#MyAppExeName}";Parameters: "/register"; Flags: waituntilterminated  
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Registry]
;cl� pour associer dossier en lecture A�adir a la lista de 3nity
Root: HKCR; Subkey: "Directory\shell\PlayWith3nity"; ValueType: string; ValueName: ""; ValueData: "Play with 3nity Media Player"; Flags: uninsdeletekey
Root: HKCR; Subkey: "Directory\shell\PlayWith3nity"; ValueName: "Icon"; ValueType: String; ValueData: "{app}\3nity.exe";  Flags: uninsdeletekey 


[Code]
const
  SHCNE_ASSOCCHANGED = $08000000;
  SHCNF_IDLIST = $00000000;
  MB_ICONINFORMATION = $40;
//  CLSID_ApplicationAssociationRegistration = '{591209c7-767b-42b2-9fba-44ee4615f2c7}';
//  IID_IApplicationAssociationRegistration = '{4e530b0a-e611-4c77-a3ac-9031d022281b}';
  
  
  Fass='1264,126l,13g2,13ga,13gp,13gp2,13gpp,13gpp2,1aac,1ac3,1aif,1aifc,1aiff,1amr,1ape,'
        + '1asf,1au,1avi,1awb,1bdm,1bdmv,1bik,1bin,1cdg,1clpi,1cpi,1cpk,1dat,1divx,1dv,1f4a,'
        + '1f4b,1f4v,1flac,1flc,1fli,1flv,1jsv,1m1v,1m2t,1m2ts,1m2v,1m3u,1m4a,1m4b,1m4v,1mjpg,'
        + '1mka,1mkv,1moov,1mov,1mp1,1mp2,1mp2,1mp3,1mp4,1mpa,1mpc,1mpe,1mpeg,1mpg,1mpga,1mpl,'
        + '1mpls,1mpp,1mpv,1mts,1mxf,1nsa,1nsv,1nuv,1oga,1ogg,1ogg,1ogm,1ogv,1ogx,1pcm,1pls,'
        + '1pva,1qcp,1qt,1qtvr,1ra,1ram,1rec,1rm,1rmvb,1roq,1rv,1smk,1snd,1spl,1spx,1str,1swf,'
        + '1tak,1trp,1ts,1ty,1vdr,1viv,1vivo,1vob,1voc,1vqf,1w64,1wav,1webm,1wma,1wmv,1wv,1wvp,1y4m';



function RegAss(): Boolean;
var s: TStringList;  i: integer;
  hr: HRESULT; AppName, ext, AppPath: string;
//  AAR: IApplicationAssociationRegistration;
  WantedLangID:string;
  Version: TWindowsVersion;

   
begin




  GetWindowsVersionEx(Version);
  s := TStringList.Create;
  s.CommaText := FAss;
  if s.Count < 1 then begin
  s.Free; exit; end;
  
  hr := 1;
//  AAR := nil; 
  ext := ''; AppName := '3nityMediaPlayer';
  AppPath := ExpandConstant('{app}'+'\'+'{#MyAppExeName}');

if (Version.Major>=6) then begin  // if windows vista seven or 8 or 10
  

 
      RegWriteStringValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\RegisteredApplications',AppName, 'Software\Clients\Media\' + AppName + '\Capabilities');
  
      RegWriteExpandStringValue(HKEY_LOCAL_MACHINE, 'Software\Clients\Media\' + AppName + '\Capabilities','ApplicationDescription', '3nity  Media Player');
      RegWriteExpandStringValue(HKEY_LOCAL_MACHINE, 'Software\Clients\Media\' + AppName + '\Capabilities','ApplicationName',AppName);

  ///////////////////////
  //
  //hr := CoCreateInstance(CLSID_ApplicationAssociationRegistration, nil, CLSCTX_INPROC_SERVER, IID_IApplicationAssociationRegistration, AAR);  
 end;
  

WantedLangID:=ActiveLanguage;

if (WantedLangID='english') then RegWriteStringValue(HKEY_CLASSES_ROOT, 'Directory\shell\PlayWith3nity','', 'Play with 3nity Media Player') ;
if (WantedLangID='french') then RegWriteStringValue(HKEY_CLASSES_ROOT, 'Directory\shell\PlayWith3nity','', 'Lire avec 3nity Media Player') ;
if (WantedLangID='spanish') then RegWriteStringValue(HKEY_CLASSES_ROOT, 'Directory\shell\PlayWith3nity','', 'Reproducir con 3nity Media Player') ;

RegWriteStringValue(HKEY_CLASSES_ROOT, 'Directory\shell\PlayWith3nity\command','', '"' + AppPath + '" "%1"') ;

for i := 0 to s.Count - 1 do begin
      ext := '.' + LowerCase(copy(s.Strings[i], 2, MaxInt));
   if s.Strings[i][1] = '1' then begin//remettre � 1 plus tard

      RegWriteStringValue(HKEY_CLASSES_ROOT, AppName + ext,'', 'MPlayer file (' + ext + ')') ;
      RegWriteStringValue(HKEY_CLASSES_ROOT, AppName + ext + '\DefaultIcon','', AppPath + ',0') ;
      RegWriteStringValue(HKEY_CLASSES_ROOT, AppName + ext + '\shell\open\command','', '"' + AppPath + '" "%1"') ;
      RegWriteStringValue(HKEY_CLASSES_ROOT, ext,'', AppName + ext) ;
      
      ///////if unicode//////////////
      if (Version.NTPlatform ) then begin
        
     
       RegWriteStringValue(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\' + ext,'Progid', AppName + ext) ;
       
               /////////if vista 7 10//////////////////
               if (Version.Major>=6) then begin
               
                   RegWriteStringValue(HKEY_LOCAL_MACHINE, 'Software\Clients\Media\' + AppName + '\Capabilities\FileAssociations','ext', AppName + ext) ;
                   if hr=0 then begin
                   
                   //AAR.SetAppAsDefault(PWChar(WideString(AppName)), PWChar(WideString(ext)), AT_FILEEXTENSION);
               
                   end;
              
               end;
               /////////end if vista//////////////
      
      end;///////endif unicode///////////
  end;//end if s.strings



end;//end for
//SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, 0, 0);
 ;

  Result := True;
end;




procedure CurStepChanged(CurStep: TSetupStep);
begin

if CurStep=ssPostInstall then  RegAss;
   

end;

