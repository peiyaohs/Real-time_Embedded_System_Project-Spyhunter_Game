extern int lab7(void);	
extern int pin_connect_block_setup_for_uart0(void);
extern int UART_INIT(void);

int main() 
{ 	
   pin_connect_block_setup_for_uart0();
   UART_INIT();
   lab7();
}
