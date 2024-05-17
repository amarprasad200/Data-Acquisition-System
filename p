/*header.h*/
 extern void delay_ms(unsigned int );
extern void delay_sec(unsigned int );
extern void lcd_init(void);
extern void lcd_data(unsigned char);
extern void lcd_string(char*);
extern void uart0_init(unsigned int);
extern void uart0_tx(unsigned char);
extern void lcd_cmd(unsigned char);
extern void uart0_rx_string(char *,int);
extern void uart0_tx_float(float);
extern void uart0_tx_int(int);
extern void uart0_tx_gsm(char*);
extern void uart0_rx_gsm(char *);
extern void uart0_tx_string(char *);
extern void uart0_hex(int);
extern void adc_init(void);
extern unsigned int adc_read(unsigned int);
extern unsigned int uart0_rx(void);
extern void uart0_tx_string(char *);
extern void i2c_init(void);
extern void i2c_byte_write_frame(unsigned char ,unsigned char ,unsigned char);
extern unsigned char i2c_byte_read_frame(unsigned char sa,unsigned char mr);
extern void spi0_init(void);
extern unsigned char spi0(unsigned char data);
extern unsigned short int mcp3204_adc_read(unsigned char ch_num);
typedef struct CAN1_MSG
{
unsigned int id;
unsigned int dlc;
unsigned int rtr;
unsigned int byteA;
unsigned int byteB;
}CAN1;
extern void can1_rx(CAN1 *);
extern void can1_tx(CAN1);
extern void can1_init(void);

.................................................................................................
/*adc driver*/

#include<LPC21xx.h>
#include"header.h"
#define DONE ((ADDR>>31)&1)
void adc_init(void)
{
PINSEL1|=0x15400000;
ADCR=0x00200400;
}
unsigned int adc_read(unsigned int ch_num)
{
unsigned int result=0;
ADCR|=(1<<ch_num);//select ch_num
ADCR|=(1<<24);//Start ADC
while(DONE==0);//Monitor Done flag
ADCR^=(1<<24);//Stop ADC
ADCR^=(1<<ch_num);//disselect ch_num
//ADCR&=~(1<<24);
//ADCR&=~(1<<ch_num);
result=(ADDR>>6)&0x3FF;
return result;
}

...........................................................................................
/*delay*/
#include <LPC21xx.H>
int a[]={15,60,30,0,15};
void delay_sec(unsigned int sec)
{
unsigned int pclk=0;
pclk=a[VPBDIV]*1000000;
T0PC=0;
T0PR=pclk-1;
T0TC=0;
T0TCR=1;
while(T0TC<sec);
T0TCR=0;
}
void delay_ms(unsigned int ms)
{
unsigned int pclk=0;
pclk=a[VPBDIV]*1000;
T0PC=0;
T0PR=pclk-1;
T0TC=0;
T0TCR=1;
while(T0TC<ms);
T0TCR=0;
}

............................................................................................
/*uart_driver*/
#include<lpc21xx.h>
#include<stdio.h>
#define THRE ((U0LSR>>5)&1)
#define RDR (U0LSR&1)
void uart0_init(unsigned int baud)
{
int a[]={15,60,30,0,15};
unsigned int pclk=a[VPBDIV]*1000000;
unsigned int result=0;
result=pclk/(16*baud);
PINSEL0|=0X5;
U0LCR=0x83;
U0DLL=result&0XFF;
U0DLM=(result>>8)&0XFF;
U0LCR=0X03;
}
void uart0_tx(unsigned char data)
{
U0THR=data;
while(THRE==0);
}

void uart0_tx_string(char *ptr)
{
while(*ptr!=0)
{
U0THR=*ptr;
while(THRE==0);
ptr++;
}
}
unsigned int uart0_rx(void)
{
while(RDR==0);
return U0RBR;
}
void uart0_rx_string(char *ptr,int max_bytes)
{
int i;
for(i=0;i<max_bytes;i++)
{
while(RDR==0);
ptr[i]=U0RBR;
if(ptr[i]=='\r')
break;
}
ptr[i]='\0';
}


void uart0_tx_int(int num)
{
int a[20],i;
if(num==0)
{
uart0_tx('0');
}
if(num<0)
{
uart0_tx('-');
num=-num;
}
i=0;
while(num>0)
{
a[i]=num%10+48;
num=num/10;
i++;
}
for(--i;i>=0;i--)
{
uart0_tx(a[i]);
}
}

void uart0_tx_float(float f)
{
int i;
if(f<0)
{
uart0_tx('-');
f=-f;
} 
i=f;
uart0_tx_int(i);
uart0_tx('.');
i=(f-i)*10;
uart0_tx_int(i);
}

void uart0_tx_gsm(char *ptr)
{
while(*ptr)
{
U0THR=*ptr;
while(THRE==0);
ptr++ ;
}
}

void uart0_rx_gsm(char *ptr)
{
int i;
for(i=0;;i++)
{
while(RDR==0);
ptr[i]=U0RBR;
if(ptr[i]=='\r')
break;
}
ptr[i]='\0';
}

void uart0_hex(int num)
{
char buf[10];
sprintf(buf,"%x",num);
uart0_tx_string(buf);
}

.........................................................................................
/*i2c_driver*/
#include<lpc21xx.h>
#include"header.h"
#define SI ((I2CONSET>>3)&1)
void i2c_init(void)
{
PINSEL0|=0x50;//P0.2 as SCL and P0.3 as SDA
I2SCLH=75;//I2C speed 100 Kbps
I2SCLL=75;//I2C speed 100 Kbps
I2CONSET=(1<<6);
}



void i2c_byte_write_frame(unsigned char sa,unsigned char mr,unsigned char data)
{
I2CONSET=(1<<5);//STA=1
I2CONCLR=(1<<3);//SI=0
while(SI==0);
I2CONCLR=(1<<5);//STA=0
if(I2STAT!=0x08)
{
uart0_tx_string("Error:Start condition\r\n");
goto exit;
}
I2DAT=sa;//send SA+W
I2CONCLR=(1<<3);//SI=0
while(SI==0);
if(I2STAT==0x20)
{
 uart0_tx_string("Error:SA+Write\r\n");
 goto exit;
}
 I2DAT=mr;//send memory address
 I2CONCLR=(1<<3);//SI==0
 while(SI==0);
  if(I2STAT==0x30)
{
 uart0_tx_string("Error:Memory Address\r\n");
 goto exit;
}
  I2DAT=data;//send memory address
 I2CONCLR=(1<<3);//SI==0
 while(SI==0);
  if(I2STAT==0x30)
{
 uart0_tx_string("Error:data\r\n");
}
exit:
I2CONSET=(1<<4);//STO=1
I2CONCLR=(1<<3);//SI=0
}



unsigned char i2c_byte_read_frame(unsigned char sa,unsigned char mr)
{
unsigned char temp;
I2CONSET=(1<<5);//STA=1
I2CONCLR=(1<<3);//SI=0
while(SI==0);
I2CONCLR=(1<<5);//STA=0
if(I2STAT!=0x08)
{
uart0_tx_string("Error:Start condition\r\n");
goto exit;
}
I2DAT=sa;//send SA+W
I2CONCLR=(1<<3);//SI=0
while(SI==0);
if(I2STAT==0x20)
{
 uart0_tx_string("Error:SA+W\r\n");
 goto exit;
}
I2DAT=mr;//send memory address
 I2CONCLR=(1<<3);//SI==0
 while(SI==0);
  if(I2STAT==0x30)
{
 uart0_tx_string("Error:Memory Address\r\n");
 goto exit;
}
I2CONSET=(1<<5);//STA=1 restart condition
I2CONCLR=(1<<3);//SI=0
while(SI==0);
I2CONCLR=(1<<5);//STA=0
if(I2STAT!=0x10)
{
uart0_tx_string("Error:restart condition\r\n");
goto exit;
}
I2DAT=sa|1;//send SA+W
I2CONCLR=(1<<3);//SI=0
while(SI==0);
if(I2STAT==0x48)
{
 uart0_tx_string("Error:SA+R\r\n");
 goto exit;
}

//Data read
I2CONCLR=(1<<3);//SI=0
while(SI==0);//waiting for data to be read
temp=I2DAT;
exit:
I2CONSET=(1<<4);//STO=1
I2CONCLR=(1<<3);//SI
return temp;
}

.............................................................................................................
/*spi_driver.c*/
#include<lpc21xx.h>
#include"header.h"
#define CS0 (1<<7)
void spi0_init(void)
{
PINSEL0|=0x1500;//P0.4-->SCK0 P0.5-->MISO0  P0.6-->out direction
IODIR0|=CS0;//P0.7 CS0
IOSET0=CS0;//CS0=1(disselect slave)
S0SPCR=0x20;//CPOL=CPHA=0
S0SPCCR=15;//SPI0 frequency is 1 Mbps
}

/* SPI transfer function*/
#define SPIF ((S0SPSR>>7)&1)
unsigned char spi0(unsigned char data)
{
S0SPDR=data;//data from master to slave
while(SPIF==0);
return S0SPDR;//rx data data from slave to master
}

/*mcp3204_driver.c*/
unsigned short int mcp3204_adc_read(unsigned char ch_num)
{
unsigned char byteH=0,byteL=0,channel=0;
unsigned short int result=0;
channel=ch_num<<6;
IOCLR0=CS0;//Select slave
spi0(0x06);
byteH=spi0(channel);
byteL=spi0(0x0);
IOSET0=CS0;//Disselect slave
byteH&=0x0F;//masking higher nibble
result=(byteH<<8)|(byteL);
return result;
}

..............................................................................................
/*main*/

#include"header.h"
main()
{
unsigned char h,m,s,day,month,year;
unsigned short int ret;
unsigned int adcval,pval;
float vout,tempr,vout1,pres,light;
adc_init();
i2c_init();
spi0_init();
uart0_init(9600);
i2c_byte_write_frame(0xD0,0X2,0x08);
i2c_byte_write_frame(0xD0,0X1,0x40);
i2c_byte_write_frame(0xD0,0X0,0x50);

i2c_byte_write_frame(0xD0,0X4,0x24);
i2c_byte_write_frame(0xD0,0X5,0x02);
i2c_byte_write_frame(0xD0,0X6,0x24);

while(1)
{
ret=mcp3204_adc_read(2);//ch0
light=100-((ret*100)/4095);
uart0_tx_string("Light intensity : ");
uart0_tx_float(light);
uart0_tx('%');
uart0_tx_string("\r\n");

 uart0_tx_string("Temperature : ");
adcval=adc_read(1);
 //uart0_tx_int(adcval);
vout=(adcval*3.3)/1023;
tempr=(vout-0.5)/0.01;
//uart0_tx_string("Temperature : ");
uart0_tx_float(tempr);
uart0_tx_string("degree celsius");
uart0_tx_string("\r\n");


pval=adc_read(2);
vout1=(pval*3.3)/1023;
pres=((vout1/3.3)+0.095)/0.009;
uart0_tx_string("Pressure : ");
uart0_tx_float(pres);
uart0_tx_string("kpa");
uart0_tx_string("\r\n");

day=i2c_byte_read_frame(0XD0,0X4);//read hours
month=i2c_byte_read_frame(0XD0,0X5);//read min
year=i2c_byte_read_frame(0XD0,0X6);//read sec
uart0_tx_string("date : ");
uart0_tx((day/0x10)+48);
uart0_tx((day%0x10)+48);
uart0_tx(':');

uart0_tx((month/0x10)+48);
uart0_tx((month%0x10)+48);
uart0_tx(':');

uart0_tx((year/0x10)+48);
uart0_tx((year%0x10)+48);
uart0_tx_string("\r\n");
delay_ms(1000);
uart0_tx_string("\r\n"); 
	
h=i2c_byte_read_frame(0XD0,0X2);//read hours
m=i2c_byte_read_frame(0XD0,0X1);//read min
s=i2c_byte_read_frame(0XD0,0X0);//read sec
uart0_tx_string("Time : ");
uart0_tx((h/0x10)+48);
uart0_tx((h%0x10)+48);
uart0_tx(':');

uart0_tx((m/0x10)+48);
uart0_tx((m%0x10)+48);
uart0_tx(':');

uart0_tx((s/0x10)+48);
uart0_tx((s%0x10)+48);
uart0_tx_string("\r\n");
delay_ms(1000);
uart0_tx_string("----------------------------------");
uart0_tx_string("\r\n"); 
}
}
