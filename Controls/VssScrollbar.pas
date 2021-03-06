unit VssScrollbar;

interface
uses
  Windows, Messages, Classes, Controls, Graphics, sysutils;
type
  TVssScrollbar = class(Tcustomcontrol)
  private
    FMax: integer;
    FMin: integer;
    FPosition: integer;
    FSliderHeight: integer;
    FSliderWidth: integer;
    FScrolling: boolean;
    FBorderX: integer;
    FBorderY: integer;
    FOnChange: TNotifyEvent;
    FSliderLineHeight: integer;

    Fbitmap: Tbitmap;
    FScrollButtonColor: TColor;
    FScrollButtonDirectColor: Boolean;

    procedure SetcolorDepth();
    procedure SetMax(const Value: integer);
    procedure SetMin(const Value: integer);
    procedure SetPosition(Value: integer);
    function LimitPosition(const Value : integer): integer;
    function CalculatePosFromSlider(pos : integer) : integer;
    procedure SetSliderHeight(const Value: integer);
    procedure SetSliderWidth(const Value: integer);
    procedure WMMouseMove(var Message: TWMMouseMove); message WM_MOUSEMOVE;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure SetBorderX(const Value: integer);
    procedure SetBorderY(const Value: integer);
    procedure SetSliderLineHeight(const Value: integer);
    procedure DoOnChange();
    procedure SetScrollButtonColor(const Value: TColor);
    procedure SetScrollButtonDirectColor(const Value: Boolean);
  Public
    //count : integer; //testing
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CancelScroll;
  published
    Property Max : integer read FMax write SetMax;
    Property Min : integer read FMin write SetMin;
    Property Position : integer read FPosition write SetPosition;
    Property SliderWidth : integer read FSliderWidth write SetSliderWidth;
    Property SliderHeight : integer read FSliderHeight write SetSliderHeight;
    Property SliderLineHeight : integer read FSliderLineHeight write SetSliderLineHeight;
    Property Scrolling : boolean read FScrolling;
    Property BorderX : integer read FBorderX write SetBorderX;
    Property BorderY : integer read FBorderY write SetBorderY;
    property ScrollButtonColor : TColor read FScrollButtonColor write SetScrollButtonColor;
    property ScrollButtonDirectColor : Boolean read FScrollButtonDirectColor write SetScrollButtonDirectColor;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnMouseUp;
  protected
    FneedsRedraw : boolean;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer); override;
    procedure SetEnabled(Value: boolean); override;
    procedure Redraw(); virtual;
  end;
implementation

{ TVssScrollbar }

function TVssScrollbar.LimitPosition(const Value : integer): integer;
begin
  Result := Value;
  if Value > Fmax then
    Result := Fmax;
  if Value < Fmin then
    Result := Fmin;
end;

function TVssScrollbar.CalculatePosFromSlider(Pos : integer): integer;
var
  pixelwidth : integer;
  Valuewidth : integer;
begin
  Valuewidth := Fmax-Fmin;
  pixelwidth := Width - fsliderwidth-FBorderX*2;

  Pos := Pos - ( sliderwidth div 2) - FBorderX;
  Result := Fmin + (Pos * Valuewidth + (pixelwidth SHR 1)) div pixelwidth;
end;

procedure TVssScrollbar.CancelScroll;
begin
  if FScrolling then begin
    FScrolling := false;
    FneedsRedraw := true;
    Invalidate;
  end;
end;

constructor TVssScrollbar.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque];
  FPosition :=0;
  FMin := 0;
  Fmax := 100;
  FSliderWidth := 12;
  FSliderHeight := 18;
  FSliderLineHeight := 12;
  FScrolling := false;
  FBorderX := 0;
  FBorderY := 0;

  FScrollButtonColor := rgb(192,192,255);
  FScrollButtonDirectColor := False;

  Fbitmap := Tbitmap.Create;
  Fbitmap.PixelFormat := pf32bit;
end;

destructor TVssScrollbar.Destroy;
begin
  FreeAndNil(Fbitmap);
  inherited;
end;

procedure TVssScrollbar.DoOnChange;
begin
  if assigned(Fonchange) then
    FonChange(self);
end;

procedure TVssScrollbar.Redraw;
 function doColorize(color, TintColor : Tcolor): Tcolor;
  var
    GreyLevel : byte;
  begin
    color := ColorToRGB(color);
    TintColor := ColorToRGB(TintColor);

    GreyLevel := (getRValue(color) + getGValue(color) + getBValue(color)) div 3;
    Result := rgb((GreyLevel*getRValue(TintColor) +127) div 255,
                 (GreyLevel*getGValue(TintColor) +127) div 255,
                 (GreyLevel*getBValue(TintColor) +127) div 255);
  end;
  procedure FillrectGradient(r : Trect;startcolor, endcolor : Tcolor; intsize : integer);
  var
    i , max, f : integer;
    w, h : integer;
    R1,G1,B1,R2,G2,B2 : byte;
    bOdd : boolean;
  begin
    startcolor := ColorToRGB(startcolor);
    endcolor := ColorToRGB(endcolor);

    R1 := GetRValue(startcolor);
    G1 := GetGValue(startcolor);
    B1 := GetBValue(startcolor);
    R2 := GetRValue(endcolor);
    G2 := GetGValue(endcolor);
    B2 := GetBValue(endcolor);

    w := r.Right - r.Left;
    h := r.Bottom - r.Top;

    if w < h then
      max := w
    else
      max := h;

    max := max - intsize;
    bOdd := (max mod 2) = 1;
    max := max div 2;

    with Fbitmap do begin
    if max > 0 then begin
      for i := 0 to (max-1) do begin
        f := max -i;

        canvas.Brush.Color := rgb(
              (((R1*f) + (max div 2)) div max) + (((R2*i) + (max div 2)) div max),
              (((G1*f) + (max div 2)) div max) + (((G2*i) + (max div 2)) div max),
              (((B1*f) + (max div 2)) div max) + (((B2*i) + (max div 2)) div max));
        canvas.FrameRect(r);
        inc(r.Left);
        inc(r.Top);
        dec(r.Right);
        dec(r.Bottom);
      end;
      r.Bottom := r.Top +1;
    end;
    if bOdd then begin
      canvas.Brush.Color := rgb(r2,g2,b2);
      canvas.FrameRect(r);
    end;
    end;

  end;
var
  r : TRect;
  pixelwidth : integer;
  Valuewidth : integer;
  myShadow : Tcolor;
  myFace : Tcolor;
  myBtnHighlight : Tcolor;
  myBtnShadow : Tcolor;
  minsize : integer;
  maxsize : integer;
  difsize : integer;
begin

  SetcolorDepth;
  Fbitmap.SetSize(width,height);

  myface := doColorize(clbtnface,rgb(255,255,255));
  myShadow := doColorize(clBtnShadow,FScrollButtonColor);

  if Fscrolling then begin
    myBtnHighlight := doColorize(clbtnHighlight,rgb(255,255,0));
    myBtnShadow := doColorize(clbtnshadow,rgb(255,255,0));
  end else begin
    myBtnHighlight := clbtnHighlight;
    myBtnShadow := clbtnshadow;
  end;

  pixelwidth := Width - fsliderwidth -FBorderX*2;
  Valuewidth := Fmax-Fmin;


  with Fbitmap do begin

  Canvas.Brush.Color := clblack;
  //Canvas.Brush.Color := clbtnface;
  Canvas.Pen.Width  := 0;
  Canvas.FillRect(rect(0,0,Width,Height));

  //Canvas.Brush.Color := clbtnshadow;
  //r.Left  := FBorderX +(fsliderwidth div 2);  //valeurs originales
  r.Left  := FBorderX;
  r.Right := width ;
  //r.Right := width - r.Left; //valeurs originales
  r.Top := (height -FSliderLineHeight)div 2;
  r.Bottom := r.Top + FSliderLineHeight;
  //Canvas.FillRect(r);

  FillrectGradient(r,myface,myShadow ,0);
  //here 8514
  if Fmin < 0 then begin
    Canvas.Brush.Color := clbtnface;
    //Canvas.Brush.Color := clblack;
    r.Left := ((0-Fmin) * pixelwidth + (Valuewidth SHR 1)) div Valuewidth;
    r.Left := (FBorderX + r.Left + (FSliderWidth div 2))-1;
    r.Right   := r.Left+2;
    Canvas.FillRect(r);
  end;


  if enabled then begin

    r.Left := ((FPosition-Fmin) * pixelwidth + (Valuewidth SHR 1)) div Valuewidth;
    if r.Left < 0 then
      r.Left := 0;
    if r.Left > pixelwidth then
      r.Left := pixelwidth;
    r.Left := FBorderX + r.Left;

    r.Right := r.Left + FSliderWidth;
    R.Top :=  (Height - FSliderHeight) div 2;
    R.Bottom :=  R.Top + FSliderHeight;

    canvas.Brush.Color := myBtnShadow;
    canvas.FrameRect(r);

    r.Top:= r.Top+1;
    r.Left  := r.Left +1;
    r.Bottom:= r.Bottom-1;
    r.Right := r.Right -1;
    canvas.FrameRect(r);

    canvas.Brush.Color := myBtnHighlight;
    r.Top:= r.Top-1;
    r.Left  := r.Left -1;
    canvas.FrameRect(r);

    r.Top:= r.Top+2;
    r.Left  := r.Left +2;
    r.Bottom:= r.Bottom-1;
    r.Right := r.Right -1;

    if FScrollButtonDirectColor then
      canvas.Brush.Color := FScrollButtonColor
    else
      canvas.Brush.Color := myShadow;
    canvas.FillRect(r);

    if (FPosition = 0) and (Fmin < 0) then begin
      if (r.Bottom - r.Top) > (r.Right - r.Left)  then begin
        minsize := r.Right - r.Left;
        maxsize := r.Bottom - r.Top;
        difsize := (maxsize - minsize) div 2;
        r.Top := r.Top + difsize;
        r.Bottom := r.Bottom - difsize;
      end else begin
        maxsize := r.Right - r.Left;
        minsize := r.Bottom - r.Top;
        difsize := (maxsize - minsize) div 2;
        r.Left  := r.Left + difsize;
        r.Right  := r.Right - difsize;
      end;
      canvas.Pen.Color := myShadow;
      canvas.Brush.Color := clBtnHighlight;
      canvas.Ellipse(r);
    end;

    //canvas.Font.Color := clblack;
    //canvas.TextOut(0,0,inttostr(Fposition));
  end;
 end;

  //count := count+1;
  FneedsRedraw := false
end;

procedure TVssScrollbar.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  if Button = mbLeft then begin
    SetPosition(CalculatePosFromSlider(x));
    FScrolling := true;
    FneedsRedraw := true;
    Invalidate;
  end;
  inherited;
end;

procedure TVssScrollbar.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  if fscrolling then begin
    SetPosition(CalculatePosFromSlider(x ));
    FneedsRedraw := true;
    Invalidate;
  end;
  inherited;
  FScrolling := false;
end;

procedure TVssScrollbar.Paint;
var
  r : TRect;
begin
  if Fbitmap.Width <> self.Width then
    FneedsRedraw := true;
  if Fbitmap.Height <> self.Height then
    FneedsRedraw := true;
  if FneedsRedraw then
    Redraw;

  r := rect(0,0, Fbitmap.Width, Fbitmap.Height);
  Canvas.CopyRect(r,Fbitmap.canvas,r);
end;

procedure TVssScrollbar.SetBorderX(const Value: integer);
begin
  FBorderX := Value;
end;

procedure TVssScrollbar.SetBorderY(const Value: integer);
begin
  FBorderY := Value;
end;

procedure TVssScrollbar.SetcolorDepth;
var
  TempDC: HDC;
  i: Integer;
  pf : Tpixelformat;
begin
  TempDC:=GetDC(0);
  i:= (GetDeviceCaps( TempDC, PLANES ) *GetDeviceCaps( TempDC, BITSPIXEL ));
  ReleaseDC( 0, TempDC );

  case i of
    1:
      pf:= pf1bit;
    4:
      pf:= pf4bit;
    8:
      pf:= pf8bit;
    15:
      pf:= pf15bit;
    16:
      pf:= pf16bit;
    24:
      pf:= pf24bit;
    32:
      pf:= pf32bit;
    else
      pf:= pfdevice;
  end;
  if pf <> Fbitmap.PixelFormat then
    Fbitmap.PixelFormat := pf;
end;

procedure TVssScrollbar.SetEnabled(Value: boolean);
begin
  if Enabled <> Value then begin
    inherited;
    FneedsRedraw := true
  end;
  if not enabled then
    if Fscrolling then begin
      Fscrolling := false;
      FneedsRedraw := true;
    end;
  if FneedsRedraw then
    invalidate;
end;
procedure TVssScrollbar.SetMax(const Value: integer);
begin
  if Fmax <> value then begin
    FMax := Value;
    SetPosition(LimitPosition(Value));
    FneedsRedraw := true;
    Invalidate;
  end;
end;
procedure TVssScrollbar.SetMin(const Value: integer);
begin
  if Fmin <> value then begin
    FMin := Value;
    SetPosition(LimitPosition(Value));
    FneedsRedraw := true;
    Invalidate;
  end;
end;
procedure TVssScrollbar.SetPosition(Value: integer);
begin
  Value := LimitPosition(Value);
  if FPosition <> Value then begin
    FPosition := Value;
    DoOnChange;
    FneedsRedraw := true;
    Invalidate;
  end;
end;
procedure TVssScrollbar.SetScrollButtonColor(const Value: TColor);
begin
  if FScrollButtonColor <> Value then begin
    FScrollButtonColor := Value;
    FneedsRedraw := true;
    Invalidate;
  end;
end;

procedure TVssScrollbar.SetScrollButtonDirectColor(const Value: Boolean);
begin
  if FScrollButtonDirectColor <> Value then begin
    FScrollButtonDirectColor := Value;
    FneedsRedraw := true;
    Invalidate;
  end;
end;

procedure TVssScrollbar.SetSliderHeight(const Value: integer);
begin
  if FSliderHeight <> Value then begin
    FSliderHeight := Value;
    FneedsRedraw := true;
    Invalidate;
  end;
end;
procedure TVssScrollbar.SetSliderLineHeight(const Value: integer);
begin
  if FSliderLineHeight <> Value then begin
    FSliderLineHeight := Value;
    FneedsRedraw := true;
    Invalidate;
  end;
end;
procedure TVssScrollbar.SetSliderWidth(const Value: integer);
begin
  if FSliderWidth <> Value then begin
    FSliderWidth := Value;
    FneedsRedraw := true;
    Invalidate;
  end;
end;

procedure TVssScrollbar.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  message.Result := 1;
end;

procedure TVssScrollbar.WMMouseMove(var Message: TWMMouseMove);
begin
  if Fscrolling then
    SetPosition(CalculatePosFromSlider(message.XPos));
  inherited;
end;

end.
