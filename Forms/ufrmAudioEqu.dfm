object frmAudioEqu: TfrmAudioEqu
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Equalizer'
  ClientHeight = 182
  ClientWidth = 418
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnHide = FormHide
  OnMouseWheel = FormMouseWheel
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TsLabel
    Left = 81
    Top = 159
    Width = 28
    Height = 13
    Caption = '62.50'
  end
  object Label2: TsLabel
    Left = 115
    Top = 159
    Width = 18
    Height = 13
    Caption = '125'
  end
  object Label0: TsLabel
    Left = 42
    Top = 159
    Width = 28
    Height = 13
    Caption = '31.25'
  end
  object Label3: TsLabel
    Left = 143
    Top = 159
    Width = 18
    Height = 13
    Caption = '250'
  end
  object Label4: TsLabel
    Left = 174
    Top = 159
    Width = 18
    Height = 13
    Caption = '500'
  end
  object Label5: TsLabel
    Left = 205
    Top = 159
    Width = 14
    Height = 13
    Caption = '1 k'
  end
  object Label6: TsLabel
    Left = 236
    Top = 159
    Width = 14
    Height = 13
    Caption = '2 k'
  end
  object Label7: TsLabel
    Left = 267
    Top = 159
    Width = 14
    Height = 13
    Caption = '4 k'
  end
  object Label8: TsLabel
    Left = 298
    Top = 159
    Width = 14
    Height = 13
    Caption = '8 k'
  end
  object Label9: TsLabel
    Left = 329
    Top = 159
    Width = 20
    Height = 13
    Caption = '16 k'
  end
  object LabelP12dB: TsLabel
    Left = 4
    Top = 0
    Width = 35
    Height = 13
    Caption = '+12 dB'
  end
  object LabelM12dB: TsLabel
    Left = 4
    Top = 124
    Width = 31
    Height = 13
    Caption = '-12 dB'
  end
  object Equ0: TsTrackBar
    Left = 45
    Top = 0
    Width = 25
    Height = 153
    Enabled = False
    Max = 120
    Min = -120
    Orientation = trVertical
    PageSize = 1
    TabOrder = 0
    TickStyle = tsNone
    OnMouseMove = Equ0MouseMove
    SkinData.SkinSection = 'TRACKBAR'
    BarOffsetV = 0
    BarOffsetH = 0
  end
  object Equ1: TsTrackBar
    Left = 76
    Top = 0
    Width = 25
    Height = 153
    Enabled = False
    Max = 120
    Min = -120
    Orientation = trVertical
    PageSize = 1
    TabOrder = 1
    TickStyle = tsNone
    OnMouseMove = Equ1MouseMove
    SkinData.SkinSection = 'TRACKBAR'
    BarOffsetV = 0
    BarOffsetH = 0
  end
  object Equ2: TsTrackBar
    Left = 107
    Top = 0
    Width = 25
    Height = 153
    Enabled = False
    Max = 120
    Min = -120
    Orientation = trVertical
    PageSize = 1
    TabOrder = 2
    TickStyle = tsNone
    OnMouseMove = Equ2MouseMove
    SkinData.SkinSection = 'TRACKBAR'
    BarOffsetV = 0
    BarOffsetH = 0
  end
  object Equ3: TsTrackBar
    Left = 138
    Top = 0
    Width = 25
    Height = 153
    Enabled = False
    Max = 120
    Min = -120
    Orientation = trVertical
    PageSize = 1
    TabOrder = 3
    TickStyle = tsNone
    OnMouseMove = Equ3MouseMove
    SkinData.SkinSection = 'TRACKBAR'
    BarOffsetV = 0
    BarOffsetH = 0
  end
  object Equ4: TsTrackBar
    Left = 169
    Top = 0
    Width = 25
    Height = 153
    Enabled = False
    Max = 120
    Min = -120
    Orientation = trVertical
    PageSize = 1
    TabOrder = 4
    TickStyle = tsNone
    OnMouseMove = Equ4MouseMove
    SkinData.SkinSection = 'TRACKBAR'
    BarOffsetV = 0
    BarOffsetH = 0
  end
  object Equ5: TsTrackBar
    Left = 200
    Top = 0
    Width = 25
    Height = 153
    Enabled = False
    Max = 120
    Min = -120
    Orientation = trVertical
    PageSize = 1
    TabOrder = 5
    TickStyle = tsNone
    OnMouseMove = Equ5MouseMove
    SkinData.SkinSection = 'TRACKBAR'
    BarOffsetV = 0
    BarOffsetH = 0
  end
  object Equ6: TsTrackBar
    Left = 231
    Top = 0
    Width = 25
    Height = 153
    Enabled = False
    Max = 120
    Min = -120
    Orientation = trVertical
    PageSize = 1
    TabOrder = 6
    TickStyle = tsNone
    OnMouseMove = Equ6MouseMove
    SkinData.SkinSection = 'TRACKBAR'
    BarOffsetV = 0
    BarOffsetH = 0
  end
  object Equ7: TsTrackBar
    Left = 262
    Top = 0
    Width = 25
    Height = 153
    Enabled = False
    Max = 120
    Min = -120
    Orientation = trVertical
    PageSize = 1
    TabOrder = 7
    TickStyle = tsNone
    OnMouseMove = Equ7MouseMove
    SkinData.SkinSection = 'TRACKBAR'
    BarOffsetV = 0
    BarOffsetH = 0
  end
  object Equ8: TsTrackBar
    Left = 293
    Top = 0
    Width = 25
    Height = 153
    Enabled = False
    Max = 120
    Min = -120
    Orientation = trVertical
    PageSize = 1
    TabOrder = 8
    TickStyle = tsNone
    OnMouseMove = Equ8MouseMove
    SkinData.SkinSection = 'TRACKBAR'
    BarOffsetV = 0
    BarOffsetH = 0
  end
  object Equ9: TsTrackBar
    Left = 324
    Top = 0
    Width = 25
    Height = 153
    Enabled = False
    Max = 120
    Min = -120
    Orientation = trVertical
    PageSize = 1
    TabOrder = 9
    TickStyle = tsNone
    OnMouseMove = Equ9MouseMove
    SkinData.SkinSection = 'TRACKBAR'
    BarOffsetV = 0
    BarOffsetH = 0
  end
  object CheckActive: TsCheckBox
    Left = 355
    Top = 0
    Width = 67
    Height = 17
    Caption = 'ON/OFF'
    TabOrder = 10
    OnClick = CheckActiveClick
    ImgChecked = 0
    ImgUnchecked = 0
    SkinData.SkinSection = 'CHECKBOX'
  end
  object btnreset: TButton
    Left = 355
    Top = 66
    Width = 46
    Height = 24
    Caption = 'reset'
    TabOrder = 11
    OnClick = btnresetClick
  end
end
