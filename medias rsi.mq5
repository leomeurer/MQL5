//+------------------------------------------------------------------+
//|                                                     testando.mq5 |
//|                                                  Leonardo Meurer |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Leonardo Meurer"
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
input double TK                           = 60;
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
int rsi_Buffer[];

//Variables for functions
int magic_number = 112233;

MqlRates candle[];
MqlTick tick;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   ma_fast_Handle = iMA(_Symbol,ma_time_graphic,ma_fast_period,0,ma_method,ma_price);
   ma_slow_Handle = iMA(_Symbol,ma_time_graphic,ma_slow_period,0,ma_method,ma_price);
   
   rsi_Handle = iRSI(_Symbol,rsi_time_graphic,rsi_period,rsi_price);
   
   if(ma_fast_Handle < 0 || ma_slow_Handle < 0 || rsi_Handle <0)
     {
      Alert("Problemas detectado ao criar Handle dos indicadores ", GetLastError()," !");
      return(-1);
     }
     
   CopyRates(_Symbol,_Period,0,4,candle);
   ArraySetAsSeries(candle,true);
   
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
   
  }
  
//+------------------------------------------------------------------+
//| FUNCTIONS TO ASSIST IN THE VISUALIZATION OF THE STRATEGY         |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| FUNCTIONS FOR SENDING ORDERS                                     |
//+------------------------------------------------------------------+


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
  
  
//+------------------------------------------------------------------+

