//+------------------------------------------------------------------+
//|                                                     MC_EA_V0.mq5 |
//|                                  https://t.me/mahdi_ebrahimzadeh |
//|                                          https://www.pipcrop.com |
//+------------------------------------------------------------------+
#property copyright "https://t.me/mahdi_ebrahimzadeh"
#property link      "https://www.pipcrop.com"
#property version   "1.00"

#include <trade/trade.mqh>
#include <trade/DealInfo.mqh>
#include <Trade/SymbolInfo.mqh>

sinput group "General Settings"
input int MagNumber = 123;                                           // Magic Number
input int TPCounter = 5;                                             // Max. No of Open Positions

sinput group "Signal Generation Settings"
input int NoBCandles = 2;                                            // Number of Look back candles for Higher High
input double ROC = 75.0;                                             // Rate of Change Limit
input int RCOshift = 200;                                            // ROC look back number of candles
input ENUM_MA_METHOD MA_Mode = MODE_SMA;                             // MA Mode
input ENUM_APPLIED_PRICE MA_APrice = PRICE_CLOSE;                     // MA Applied Price
input int MAPer = 200;                                               // MA Period

sinput group "Trade Settings"
input double Risk = 100.0;                                            // Risk amount (20 = 20%)


//-- Overal Variables
int filehandle = 0, count = 0, size = 0, Digit = 0, BuyC = 0, SellC = 0, MA_handler = 0;
double Spread = 0.0, Lot = 0.0, LotStep = 0.0, LotMin = 0.0, Points = 0.0, Ask = 0.0, Bid = 0.0, MA200, Close = 0.0, ROCValue = 0.0, MA[], Balance = 0.0, High7 = 0.0, Low7 = 0.0;
string filename = "Symbol_List.CSV";
string Syms[], SelSymbol = "";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  Print(GetLastError());

   // --- Refresh object creation on chart --------------------------
   if (ObjectFind(ChartID(), "Refresh")<0)
      {
      ObjectCreate(ChartID(), "Refresh", OBJ_EDIT,0,0,0);
      ObjectSetInteger(ChartID(), "Refresh", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
      ObjectSetInteger(ChartID(), "Refresh", OBJPROP_XDISTANCE, 80);
      ObjectSetInteger(ChartID(), "Refresh", OBJPROP_YDISTANCE, 25);
      ObjectSetInteger(ChartID(), "Refresh", OBJPROP_XSIZE, 75);
      ObjectSetInteger(ChartID(), "Refresh", OBJPROP_YSIZE, 20);
      ObjectSetInteger(ChartID(), "Refresh", OBJPROP_FONTSIZE, 12);
      ObjectSetInteger(ChartID(), "Refresh", OBJPROP_COLOR, clrGray);
      ObjectSetString(ChartID(), "Refresh", OBJPROP_TEXT, "Refrsh");
      ObjectSetInteger(ChartID(), "Refresh", OBJPROP_BGCOLOR, clrPink);
      ObjectSetInteger(ChartID(), "Refresh", OBJPROP_BORDER_COLOR, clrBlack);
      ObjectSetInteger(ChartID(), "Refresh", OBJPROP_SELECTABLE, false);
      ObjectSetInteger(ChartID(), "Refresh", OBJPROP_READONLY, true);
      ObjectSetInteger(ChartID(), "Refresh",OBJPROP_ALIGN, ALIGN_CENTER);
      ObjectSetInteger(ChartID(), "Refresh",OBJPROP_BACK, false);
      }
      
   if (ArraySize(Syms) == 0) {ArrayResize(Syms, count +1, 0); Syms[0] = Symbol();};   
   size = ArraySize(Syms);
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   
   for (int i = 0; i<= size-1; i++)
      {
      SelSymbol = Syms[i];
      FillSymbol();
      Print(TotalPosCounter(SelSymbol),"  ",Close,"  ",High7);
      if (TotalPosCounter(SelSymbol) > 0 && Close >= High7) CloseAllPos(POSITION_TYPE_BUY);
      
      if (Close <= Low7 &&
          Close > MA200
          )
          {
          Lot = MathFloor(Balance * Risk / 100.0 / LotMin / Ask) * LotMin;

          if (Lot >= LotMin && TotalPosCounter("All") < TPCounter && TotalPosCounter(SelSymbol) == 0) 
             {
             bool checkBuy = DoTrade(SelSymbol, ORDER_TYPE_BUY, Lot, Ask, 0.0, 0.0, "", 100);
             if (checkBuy) Print("Buy position on ",SelSymbol,"!");
             }
          }          
      }
      
      Comment("ROCValue: ", ROCValue, "\n",
             "Close: ", Close, "\n", "Low7: ", Low7, "\n", "High7: ", High7, "\n"  );         
              

   
   return;
}
//+------------------------------------------------------------------+
datetime LastPosDate(string Sym)
{
   int NumPos = PositionsTotal();
   datetime ret = 0;
   
   for (int i=NumPos - 1; i>=0;i--)
      {
      ulong  position_ticket = PositionGetTicket(i);                                      // ticket of the position
      
      if (PositionSelectByTicket(position_ticket))                                        // Check if Position selected correctly?
         {
         string position_symbol = PositionGetString(POSITION_SYMBOL);                        // Position symbol  
         ulong  magic = PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber of the position 
         datetime position_opentime = (datetime) PositionGetInteger(POSITION_TIME);          // Position Open Time
   
         if (position_symbol == Sym && magic == MagNumber && ret < position_opentime)
            ret = position_opentime;
         }   
      }

   return(ret);
}
//+------------------------------------------------------------------+
void CloseAllPos(ENUM_POSITION_TYPE PosType)
{
   int NumPos = PositionsTotal();
   CTrade trade;

   for (int i=NumPos - 1; i>=0;i--)
   {
      ulong  position_ticket=PositionGetTicket(i);                      // ticket of the position
      
      if (PositionSelectByTicket(position_ticket))
      {
      string position_symbol = PositionGetString(POSITION_SYMBOL);        // symbol  
      ulong  magic = PositionGetInteger(POSITION_MAGIC);                  // MagicNumber of the position 

      if (position_symbol == SelSymbol && magic == MagNumber && PosType == PositionGetInteger(POSITION_TYPE))
         trade.PositionClose(position_ticket, 100);
      }   
   }

   return;
}
//+------------------------------------------------------------------+
int TotalPosCounter(string Sym)
{
   int ret = 0;
   BuyC = 0; SellC = 0; 
   int TO = PositionsTotal()-1;
   for (int i=TO;i>=0;i--)
      {
      ulong Ticket = PositionGetTicket(i);
      
      if (PositionSelectByTicket(Ticket) && PositionGetInteger(POSITION_MAGIC) == MagNumber && (PositionGetString(POSITION_SYMBOL) == Sym || Sym == "All")) 
         {
         ret = ret + 1;
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) BuyC++;
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) SellC++;
         }
      }
   
   return(ret);
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if (id == CHARTEVENT_OBJECT_CLICK && sparam == "Refresh") 
      {
      ObjectSetString(ChartID(), "Refresh", OBJPROP_TEXT, "Processing...");
      ChartRedraw(ChartID());
      RefreshSymbol();
      Print("Symbol List refreshed!");
      ObjectSetString(ChartID(), "Refresh", OBJPROP_TEXT, "Refrsh");
      }

}
//+------------------------------------------------------------------+
void RefreshSymbol()
{
   
   count = 0;
   // --- Symbols file handler settings -----------------------------
   filehandle = FileOpen(filename,FILE_WRITE|FILE_READ|FILE_CSV,",");

   if(filehandle < 0)
      {
      Print("Failed to open the ", filename," file!");
      Print("Error code ",GetLastError());
      }
   else
      {
      Print("File ", filename," is opened correctly!");
      while(!FileIsEnding(filehandle))
         {
         
         ArrayResize(Syms, count +1, 0);
         Syms[count] = FileReadString(filehandle);
         Print("Symbol No. ", count + 1," is ", Syms[count]);
         count++;
         }   
      FileClose(filehandle);   
      }

   return;   
}
//+--- Fill all Current Symbol Calculations like Ask/Bid/Spread and ... --------------------------------------------------------+
void FillSymbol()
{
   if (!SymbolSelect(SelSymbol, true)) {Print("Symbol ",SelSymbol," Could not find at Symbol List!"); return;}
   
   Close = iClose(SelSymbol, PERIOD_D1, 1);
   ROCValue = (Close/iClose(SelSymbol, PERIOD_D1, RCOshift) - 1.0) *100.0;
   
   MA_handler = iMA(SelSymbol, PERIOD_D1, MAPer, 0, MA_Mode, MA_APrice);
   if (MA_handler>0 && CopyBuffer(MA_handler, 0, 0, 2, MA) > 0) 
      {
      //Print(SelSymbol, " MA is copied succesfully!");
      MA200 = MA[1];
      }
   
   High7 = iHigh(SelSymbol, PERIOD_D1, iHighest(SelSymbol, PERIOD_D1, MODE_CLOSE, NoBCandles, 2));
   Low7 = iLow(SelSymbol, PERIOD_D1, iLowest(SelSymbol, PERIOD_D1, MODE_CLOSE, NoBCandles, 2));
   Balance = AccountInfoDouble(ACCOUNT_BALANCE);
   ENUM_SYMBOL_CALC_MODE CalcMode = (ENUM_SYMBOL_CALC_MODE) SymbolInfoInteger(SelSymbol, SYMBOL_TRADE_CALC_MODE);
   
   Ask = SymbolInfoDouble(SelSymbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(SelSymbol, SYMBOL_BID);
   LotMin = SymbolInfoDouble(SelSymbol, SYMBOL_VOLUME_MIN);
   LotStep = SymbolInfoDouble(SelSymbol, SYMBOL_VOLUME_STEP);
   Spread =  Ask - Bid;

   Points = SymbolInfoDouble(SelSymbol, SYMBOL_POINT);
   if (Points == 3 || Points == 5) Points = Points * 10.0;
}
//+------------------------------------------------------------------+
bool DoTrade(string Sym, ENUM_ORDER_TYPE OType, double lot, double price, double sl, double tp, string com, int Slipagging)
{
   MqlTradeRequest request_Trade ={0};
   MqlTradeResult  result_Trade ={0};
   bool TicketInternal;
   ENUM_TRADE_REQUEST_ACTIONS TA = TRADE_ACTION_DEAL;
   if (OType == ORDER_TYPE_BUY || OType == ORDER_TYPE_SELL) TA = TRADE_ACTION_DEAL;
   if (OType == ORDER_TYPE_BUY_LIMIT || OType == ORDER_TYPE_SELL_LIMIT || OType == ORDER_TYPE_BUY_STOP || OType == ORDER_TYPE_SELL_STOP) TA = TRADE_ACTION_PENDING;
   int tc = 0;
   TicketInternal = false;
   
   while(!TicketInternal && tc<=10)
      {
      ZeroMemory(request_Trade);
      ZeroMemory(result_Trade);
      request_Trade.action         = TA;                      // type of trade operation
      request_Trade.symbol         = Sym;                     // symbol
      request_Trade.volume         = lot;                     // volume of 0.1 lot
      request_Trade.type           = OType;                   // order type
      request_Trade.price          = price;                   // price for opening
      request_Trade.deviation      = Slipagging;              // allowed deviation from the price
      request_Trade.sl             = sl;                      // Stop Loss of the position
      request_Trade.tp             = tp;                      // Take Profit of the position   
      request_Trade.magic          = MagNumber;
      request_Trade.comment        = com;
      
      if (SymbolInfoInteger(Symbol(), SYMBOL_FILLING_MODE) == SYMBOL_FILLING_IOC) request_Trade.type_filling   = ORDER_FILLING_IOC;
      if (SymbolInfoInteger(Symbol(), SYMBOL_FILLING_MODE) == SYMBOL_FILLING_FOK) request_Trade.type_filling   = ORDER_FILLING_FOK;
      
      TicketInternal = OrderSend(request_Trade , result_Trade);
      
      if (!TicketInternal) Print(result_Trade.retcode);
      
      Sleep(100);tc++;
      }
   return TicketInternal;   
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if (reason == 1)
      {
      EventKillTimer();
      ObjectDelete(ChartID(), "Refresh");
      }   
   
  }
//+------------------------------------------------------------------+
double NDouble(double X, int Y)
{
   return(StringToDouble(DoubleToString(X,Y)));
}
