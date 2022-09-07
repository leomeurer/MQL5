//+------------------------------------------------------------------+
//|                                                     testando.mq5 |
//|                                                  Leonardo Meurer |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Leonardo Meurer 2"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Declaração de variáveis                                          |
//+------------------------------------------------------------------+
enum STRATEGY_IN
  {
   ONLY_MA,  	// Only moving averages
   ONLY_RSI, 	// Only RSI
   MA_AND_RSI	// moving averages plus RSI
  };

// Strategy
sinput string s0;  //-----------Strategy-------------
input STRATEGY_IN strategy                = ONLY_MA;

// Moving Averages
sinput string s1; //-----------Moving Averages-------------
input int ma_fast_period                  = 9;
input int ma_slow_period                  = 21;
input ENUM_TIMEFRAMES ma_time_graphic     = PERIOD_CURRENT;
input ENUM_MA_METHOD ma_method            = MODE_SMA;
input ENUM_APPLIED_PRICE ma_price         = PRICE_CLOSE;

//RSI
sinput string s2; //-----------RSI-------------
input int rsi_period                      = 5;
input ENUM_TIMEFRAMES rsi_time_graphic    = PERIOD_CURRENT;
input ENUM_APPLIED_PRICE rsi_price        = PRICE_CLOSE;
input int rsi_overbought                  = 70;
input int rsi_oversold                    = 30;

//Other
sinput string s3; //---------------------------
input double num_lots                     = 0.01;
input double TP                           = 60;
input double SL                           = 30;
input string limit_close_op               = "17:00";

//For indicators
//Fast moving
int ma_fast_Handle;
double ma_fast_Buffer[];

//Slow moving
int ma_slow_Handle;
double ma_slow_Buffer[];

//RSI
int rsi_Handle;
double rsi_Buffer[];

//Variables for functions
int magic_number = 112233;

MqlRates rates[];
int copiedRates;
MqlTick tick;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   ma_fast_Handle = getHandleMa(ma_fast_period);
   ma_slow_Handle = getHandleMa(ma_slow_period);
   
   rsi_Handle = iRSI(_Symbol,rsi_time_graphic,rsi_period,rsi_price);
   
   if(ma_fast_Handle < 0 || ma_slow_Handle < 0 || rsi_Handle <0)
     {
      Alert(__FUNCTION__," Problemas detectado ao criar Handle dos indicadores ", GetLastError()," !");
      return(-1);
     }
     
   CopyRates(_Symbol,_Period,0,4,rates);
   ArraySetAsSeries(rates,true);
   
   ChartIndicatorAdd(0,0,ma_fast_Handle);     
   ChartIndicatorAdd(0,0,ma_slow_Handle);
   ChartIndicatorAdd(0,1,rsi_Handle);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   IndicatorRelease(ma_fast_Handle);
   IndicatorRelease(ma_slow_Handle);
   IndicatorRelease(rsi_Handle);   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   //Copy buffers
   CopyBuffer(ma_fast_Handle,0,0,4,ma_fast_Buffer);
   CopyBuffer(ma_slow_Handle,0,0,4,ma_slow_Buffer);
   CopyBuffer(rsi_Handle,0,0,4,rsi_Buffer);
   
   //Copy Rates
   copiedRates = CopyRates(_Symbol,_Period,0,4,rates);
   
   if(copiedRates > 0)
     {
      Print("RatesInfo: copied "+ IntegerToString(copiedRates));
      string format = "open = %G, high = %G, low = %G, close = %G, volume = %d";
      string out;
      int size = fmin (copiedRates,4);
      for(int i=0; i<size; i++)
        {
         out=IntegerToString(i)+":"+TimeToString(rates[i].time);
         out=out+" "+StringFormat(format,
                                  rates[i].open,
                                  rates[i].high,
                                  rates[i].low,
                                  rates[i].close,
                                  rates[i].tick_volume);
         Print(out);
        }
     }else
       {
        Print("Failed to get history data for the symbol ",_Symbol);
       } 
   
   //Copy tick  
   if(SymbolInfoTick(_Symbol,tick))
     {
      Print("TickInfo: ", tick.time,
            " Bid = ",tick.bid, 
            " Ask = ",tick.ask,
            " Volume = ",tick.volume,
            " Last = ", tick.last,
            " Flag = ", tick.flags
            );
     }
   else Print("SymbolInfoTick() fail, error = ",GetLastError());
   
   //Sort vectors
   ArraySetAsSeries(rates,true);
   ArraySetAsSeries(ma_fast_Buffer,true);
   ArraySetAsSeries(ma_slow_Buffer,true);
   ArraySetAsSeries(rsi_Buffer,true);
   

  
   
  
  
   
//---
   
   

   
  }
  
//+------------------------------------------------------------------+
//| FUNCTIONS TO ASSIST IN THE VISUALIZATION OF THE STRATEGY         |
//+------------------------------------------------------------------+
void drawVerticalLine(string name, datetime dt, color cor=clrAliceBlue)
  {
   ObjectDelete(0,name);
   ObjectCreate(0,name,OBJ_VLINE,0,dt,0);
   ObjectSetInteger(0,name,OBJPROP_COLOR,cor);
  }

//+------------------------------------------------------------------+
//| FUNCTIONS FOR SENDING ORDERS                                     |
//+------------------------------------------------------------------+

//Execute order at Market
void ExecuteOrderAtMarket(ENUM_ORDER_TYPE orderType, double tick_price)
  {
  
   MqlTradeRequest request;
   MqlTradeResult result;
   
   ZeroMemory(request);
   ZeroMemory(result);
   
   //For Buy Order
   request.action          = TRADE_ACTION_DEAL;
   request.magic           = magic_number;
   request.symbol          = _Symbol;
   request.volume          = num_lots;   
   request.price           = NormalizeDouble(tick_price, _Digits);
   request.sl              = NormalizeDouble(tick_price - SL * _Point, _Digits);
   request.tp              = NormalizeDouble(tick_price - TP * _Point, _Digits);
   request.deviation       = 0;
   request.type            = orderType;
   request.type_filling    = ORDER_FILLING_FOK;
   
   bool res = OrderSend(request,result);
   
   if(res && (result.retcode == 10008 || result.retcode == 10009))
     {
      Print(__FUNCTION__," Order ", orderType ,"  executed successfully at ", tick_price ," in volume ", num_lots ,"!!");
     }
   else
     {
       Print(__FUNCTION__," Error sending Order to Buy. Error = ", GetLastError());
       ResetLastError();
     }  
  }


//Buy at Market
void BuyAtMarket()
  {
   MqlTradeRequest request;
   MqlTradeResult result;
   
   ZeroMemory(request);
   ZeroMemory(result);
   
   //For Buy Order
   request.action          = TRADE_ACTION_DEAL;
   request.magic           = magic_number;
   request.symbol          = _Symbol;
   request.volume          = num_lots;
   request.price           = NormalizeDouble(tick.ask, _Digits);
   request.sl              = NormalizeDouble(tick.ask - SL * _Point, _Digits);
   request.tp              = NormalizeDouble(tick.ask - TP * _Point, _Digits);
   request.deviation       = 0;
   request.type            = ORDER_TYPE_BUY;
   request.type_filling    = ORDER_FILLING_FOK;
   
   bool res = OrderSend(request,result);
   
   if(res && (result.retcode == 10008 || result.retcode == 10009))
     {
      Print(__FUNCTION__," Order Buy executed successfully at ", tick.ask ," in volume ", num_lots ,"!!");
     }
   else
     {
       Print(__FUNCTION__," Error sending Order to Buy. Error = ", GetLastError());
       ResetLastError();
     }  
  }
  
//Sell at Market
void SellAtMarket()
  {
   MqlTradeRequest request;
   MqlTradeResult result;
   
   ZeroMemory(request);
   ZeroMemory(result);
   
   //For Sell Order
   request.action          = TRADE_ACTION_DEAL;
   request.magic           = magic_number;
   request.symbol          = _Symbol;
   request.volume          = num_lots;
   request.price           = NormalizeDouble(tick.bid, _Digits);
   request.sl              = NormalizeDouble(tick.bid - SL * _Point, _Digits);
   request.tp              = NormalizeDouble(tick.bid - TP * _Point, _Digits);
   request.deviation       = 0;
   request.type            = ORDER_TYPE_SELL;
   request.type_filling    = ORDER_FILLING_FOK;
   
   bool res = OrderSend(request,result);
   
   if(res && (result.retcode == 10008 || result.retcode == 10009))
     {
      Print(__FUNCTION__," Order Sell executed successfully at ", tick.bid ," in volume ", num_lots ,"!!");
     }
   else
     {
       Print(__FUNCTION__," Error sending Order to Sell. Error = ", GetLastError());
       ResetLastError();
     }  
  }
  

//Close Buy
void CloseBuy()
  {
   MqlTradeRequest request;
   MqlTradeResult result;
   
   ZeroMemory(request);
   ZeroMemory(result);
   
   //For Close Buy Order
   request.action          = TRADE_ACTION_DEAL;
   request.magic           = magic_number;
   request.symbol          = _Symbol;
   request.volume          = num_lots;
   request.price           = 0;   
   request.type            = ORDER_TYPE_SELL;
   request.type_filling    = ORDER_FILLING_RETURN;
   
   bool res = OrderSend(request,result);
   
   if(res && (result.retcode == 10008 || result.retcode == 10009))
     {
      Print(__FUNCTION__," Order Sell to close Buy executed successfully in volume ", num_lots ,"!!");
     }
   else
     {
       Print(__FUNCTION__,"Error sending Order to Sell. Error = ", GetLastError());
       ResetLastError();
     }  
  }


//Close Sell
void CloseSell()
  {
   MqlTradeRequest request;
   MqlTradeResult result;
   
   ZeroMemory(request);
   ZeroMemory(result);
   
   //For Close Buy Order
   request.action          = TRADE_ACTION_DEAL;
   request.magic           = magic_number;
   request.symbol          = _Symbol;
   request.volume          = num_lots;
   request.price           = 0;   
   request.type            = ORDER_TYPE_BUY;
   request.type_filling    = ORDER_FILLING_RETURN;
   
   bool res = OrderSend(request,result);
   
   if(res && (result.retcode == 10008 || result.retcode == 10009))
     {
      Print(__FUNCTION__," Order Buy to close Sell executed successfully in volume ", num_lots ,"!!");
     }
   else
     {
       Print(__FUNCTION__,"Error sending Order to Buy. Error = ", GetLastError());
       ResetLastError();
     }  
  }



  

//+------------------------------------------------------------------+
//| USEFUL FUNCTIONS                                                 |
//+------------------------------------------------------------------+
//--- for bar change
bool isNewBar()
  {
//--- memorize the time of opening of the last bar in the static variable
   static datetime last_time=0;
//--- current time
   datetime lastbar_time= (datetime) SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE); 

//--- if it is the first call of the function
   if(last_time==0)
     {
      //--- set the time and exit
      last_time=lastbar_time;
      return(false);
     }

//--- if the time differs
   if(last_time!=lastbar_time)
     {
      //--- memorize the time and return true
      last_time=lastbar_time;
      return(true);
     }
//--- if we passed to this line, then the bar is not new; return false
   return(false);
  }  
 
  
//-- get Moving Average of a period
int getHandleMa(int period)
  {
   return iMA(_Symbol,ma_time_graphic,period,0,ma_method,ma_price);
  }
  
//+------------------------------------------------------------------+

