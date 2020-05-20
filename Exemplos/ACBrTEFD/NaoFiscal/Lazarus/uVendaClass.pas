unit uVendaClass;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, IniFiles;

const
  cPagamentos: array[0..4] of array [0..1] of String =
     ( ('01','Dinheiro'),
       ('02','Cheque'),
       ('03','Cartão de Crédito'),
       ('04','Cartão de Débito'),
       ('99','Outros') );

type
  TStatusVenda = (stsLivre, stsIniciada, stsEmPagamento, stsFinalizada, stsCancelada);

  { TPagamento }

  TPagamento = class
  private
    FConfirmada: Boolean;
    FHora: TDateTime;
    FNSU: String;
    FRede: String;
    FTipoPagamento: String;
    FValor: Currency;

  public
    constructor Create;
    procedure Clear;

    property TipoPagamento: String read FTipoPagamento write FTipoPagamento;
    property Valor: Currency read FValor write FValor;
    property Hora: TDateTime read FHora write FHora;
    property NSU: String read FNSU write FNSU;
    property Rede: String read FRede write FRede;
    property Confirmada: Boolean read FConfirmada write FConfirmada;
  end;

  { TListaPagamentos }

  TListaPagamentos = class(TObjectList)
  private
    function GetTotalPago: Double;
  protected
    procedure SetObject(Index: Integer; Item: TPagamento);
    function GetObject(Index: Integer): TPagamento;
  public
    function New: TPagamento;
    function Add(Obj: TPagamento): Integer;
    procedure Insert(Index: Integer; Obj: TPagamento);
    property Objects[Index: Integer]: TPagamento read GetObject write SetObject; default;

    property TotalPago: Double read GetTotalPago;
  end;

  { TVenda }

  TVenda = class
  private
    FArqVenda: String;
    FDHInicio: TDateTime;
    FNumOperacao: Integer;
    FStatus: TStatusVenda;
    FValorInicial: Currency;
    FTotalAcrescimo: Currency;
    FTotalDesconto: Currency;
    FPagamentos: TListaPagamentos;
    function GetTotalVenda: Currency;
    function GetTotalPago: Currency;
    function GetTroco: Currency;

    function SecPag(i: integer): String;
  public
    constructor Create(const ArqVenda: String);
    destructor Destroy; override;
    procedure Clear;

    procedure Gravar;
    procedure Ler;

    property NumOperacao: Integer read FNumOperacao write FNumOperacao;
    property DHInicio: TDateTime read FDHInicio write FDHInicio;
    property Status: TStatusVenda read FStatus write FStatus;

    property ValorInicial: Currency read FValorInicial write FValorInicial;
    property TotalDesconto: Currency read FTotalDesconto write FTotalDesconto;
    property TotalAcrescimo: Currency read FTotalAcrescimo write FTotalAcrescimo;
    property TotalVenda: Currency read GetTotalVenda;

    property Pagamentos: TListaPagamentos read FPagamentos;
    property TotalPago: Currency read GetTotalPago;
    property Troco: Currency read GetTroco;
  end;


Function DescricaoTipoPagamento(const ATipoPagamento: String): String;

implementation

uses
  math,
  ACBrUtil;

function DescricaoTipoPagamento(const ATipoPagamento: String): String;
var
  l, i: Integer;
begin
  Result := '';
  l := Length(cPagamentos)-1;
  For i := 0 to l do
  begin
    if ATipoPagamento = cPagamentos[i,0] then
    begin
      Result := cPagamentos[i,1];
      Break;
    end;
  end;
end;

{ TPagamento }

constructor TPagamento.Create;
begin
  inherited;
  Clear;
end;

procedure TPagamento.Clear;
begin
  FTipoPagamento := cPagamentos[0,0];
  FHora := 0;
  FValor := 0;
  FNSU := '';
  FRede := '';
  FConfirmada := False;
end;

{ TListaPagamentos }

function TListaPagamentos.GetTotalPago: Double;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Count-1 do
  begin
    with Objects[I] do
      Result := Result + Valor;
  end;

  Result := RoundTo(Result, -2);
end;

procedure TListaPagamentos.SetObject(Index: Integer; Item: TPagamento);
begin
  inherited SetItem(Index, Item);
end;

function TListaPagamentos.GetObject(Index: Integer): TPagamento;
begin
  Result := inherited GetItem(Index) as TPagamento;
end;

function TListaPagamentos.New: TPagamento;
begin
  Result := TPagamento.Create;
  Result.Hora := Now;
  Add(Result);
end;

function TListaPagamentos.Add(Obj: TPagamento): Integer;
begin
  Result := inherited Add(Obj);
end;

procedure TListaPagamentos.Insert(Index: Integer; Obj: TPagamento);
begin
  inherited Insert(Index, Obj);
end;

{ TVenda }

constructor TVenda.Create(const ArqVenda: String);
begin
  FArqVenda := ArqVenda;
  FPagamentos := TListaPagamentos.Create;
  Clear;
end;

destructor TVenda.Destroy;
begin
  FPagamentos.Free;
  inherited Destroy;
end;

procedure TVenda.Clear;
begin
  FNumOperacao := 0;
  FStatus := stsLivre;
  FDHInicio := 0;
  FValorInicial := 0;
  FTotalAcrescimo := 0;
  FTotalDesconto := 0;
  FPagamentos.Clear;
end;

function TVenda.SecPag(i: integer): String;
begin
  Result := 'Pagto'+FormatFloat('000',i);
end;

procedure TVenda.Gravar;
var
  Ini: TMemIniFile;
  ASecPag: String;
  i: Integer;
begin
  Ini := TMemIniFile.Create(FArqVenda);
  try
    Ini.WriteInteger('Venda','NumOperacao', FNumOperacao);
    Ini.WriteDateTime('Venda','DHInicio', FDHInicio);
    Ini.WriteInteger('Venda','Status', Integer(FStatus));
    Ini.WriteFloat('Valores','ValorInicial', FValorInicial);
    Ini.WriteFloat('Valores','TotalAcrescimo', FTotalAcrescimo);
    Ini.WriteFloat('Valores','TotalDesconto', FTotalDesconto);

    For i := 0 to Pagamentos.Count-1 do
    begin
      ASecPag := SecPag(i);
      Ini.WriteString(ASecPag,'TipoPagamento',Pagamentos[i].TipoPagamento);
      Ini.WriteFloat(ASecPag,'Valor', Pagamentos[i].Valor);
      Ini.WriteDateTime(ASecPag,'Hora', Pagamentos[i].Hora);
      Ini.WriteString(ASecPag,'NSU', Pagamentos[i].NSU);
      Ini.WriteString(ASecPag,'Rede', Pagamentos[i].Rede);
      Ini.WriteBool(ASecPag,'Confirmada', Pagamentos[i].Confirmada);
    end;
  finally
    Ini.Free;
  end;
end;

procedure TVenda.Ler;
var
  Ini: TMemIniFile;
  i: Integer;
  APag: TPagamento;
  ASecPag: String;
begin
  Clear;
  Ini := TMemIniFile.Create(FArqVenda);
  try
    FNumOperacao := Ini.ReadInteger('Venda','NumOperacao', 0);
    FDHInicio := Ini.ReadDateTime('Venda','DHInicio', Now);
    FStatus := TStatusVenda(Ini.WriteInteger('Venda','Status', 0));
    FValorInicial := Ini.ReadFloat('Valores','ValorInicial', 0);
    FTotalAcrescimo := Ini.ReadFloat('Valores','TotalAcrescimo', 0);
    FTotalDesconto := Ini.ReadFloat('Valores','TotalDesconto', 0);

    i := 1;
    ASecPag := SecPag(i);
    while Ini.SectionExists(ASecPag) do
    begin
      APag := TPagamento.Create;
      APag.TipoPagamento := Ini.ReadString(ASecPag,'TipoPagamento','99');
      APag.Valor := Ini.ReadFloat(ASecPag,'Valor', 0);
      APag.Hora := Ini.ReadDateTime(ASecPag,'Hora', 0);
      APag.NSU := Ini.ReadString(ASecPag,'NSU', '');
      APag.Rede := Ini.ReadString(ASecPag,'Rede', '');
      APag.Confirmada := Ini.ReadBool(ASecPag,'Confirmada', False);

      Pagamentos.Add(APag);

      Inc(i);
      ASecPag := SecPag(i);
    end;
  finally
    Ini.Free;
  end;
end;

function TVenda.GetTotalPago: Currency;
begin
  Result := Pagamentos.TotalPago;
end;

function TVenda.GetTroco: Currency;
begin
  Result := TotalPago - TotalVenda;
end;

function TVenda.GetTotalVenda: Currency;
begin
  Result := FValorInicial - FTotalDesconto + FTotalAcrescimo;
end;

end.
