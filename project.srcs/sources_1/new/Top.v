`timescale 1ns / 1ps

module Top(
    output wire TX,
    input wire RX,
    input wire CLK, // Onboard clock 100MHz : INPUT Pin W5
    input wire RESET, // Reset button / Centre Button : INPUT Pin U18
    output wire HSYNC, // VGA horizontal sync : OUTPUT Pin P19
    output wire VSYNC, // VGA vertical sync : OUTPUT Pin R19
    output reg [3:0] RED, // 4-bit VGA Red : OUTPUT Pin G19, Pin H19, Pin J19, Pin N19
    output reg [3:0] GREEN, // 4-bit VGA Green : OUTPUT Pin J17, Pin H17, Pin G17, Pin D17
    output reg [3:0] BLUE, // 4-bit VGA Blue : OUTPUT Pin N18, Pin L18, Pin K18, Pin J18/ 4-bit VGA Blue : OUTPUT Pin N18, Pin L18, Pin K18, Pin J18
    input btnR, // Right buttom : INPUT Pin T17
    input btnL // Left button : INPUT Pin W19
    );
    
    wire rst = RESET; // Setup Reset button
      
    // instantiate vga640x480 code
    wire [9:0] x; // pixel x position: 10-bit value: 0-1023 : only need 800
    wire [9:0] y; // pixel y position: 10-bit value: 0-1023 : only need 525
    wire active; // high during active pixel drawing
    wire PixCLK; // 25MHz pixel clock
    vga640x480 display (.i_clk(CLK),.i_rst(rst),.o_hsync(HSYNC), 
                        .o_vsync(VSYNC),.o_x(x),.o_y(y),.o_active(active),
                        .pix_clk(PixCLK));
    
    // uart
    reg [15:0] dL,dU,dR,dD =0;
    reg [7:0] act;
    reg [7:0] tx_byte;
    reg       transmit;
    reg       rx_fifo_pop;

    wire [7:0] rx_byte;
    wire       irq;
    wire       busy;
    wire       tx_fifo_full;
    wire       rx_fifo_empty;
    wire       is_transmitting;
  
    uart_fifo uart_fifo(
                       // Outputs
                       .rx_byte         (rx_byte[7:0]),
                       .tx              (TX),
                       .irq             (irq),
                       .busy            (busy),
                       .tx_fifo_full    (tx_fifo_full),
                       .rx_fifo_empty   (rx_fifo_empty),
                       // Inputs
                       .tx_byte         (tx_byte[7:0]),
                       .clk             (CLK),
                       .rst             (RESET),
                       .rx              (RX),
                       .transmit        (transmit),
                       .rx_fifo_pop     (rx_fifo_pop));
                       
    reg [8:0] damage = 0;
    
    // declare states
    reg is_avoid = 0;
    reg is_fight = 0;
    reg is_fight_done = 0;
    reg start_state = 1;
    reg start_game = 0;
    reg [1:0] end_state = 0;
    reg end_game = 0;
    
    // clock div
    wire targetClk;
    
    wire[28:0] tclk;
    assign tclk[0] = CLK;
 
    genvar c;
    generate for(c=0; c<29; c=c+1) begin
        clkDiv fdiv(tclk[c+1], tclk[c]);
    end endgenerate
 
    // adjust 27 to 28 to swap every 5 sec
    clkDiv fdivTarget(targetClk, tclk[25]);
    reg [21:0] time_count = 0;
    // switch state , this posedge is triggered every 2 - 5 sec
    reg [10:0] totalhit1 = 0;
    reg [10:0] totalhit2 = 0;
    reg [10:0] totalhit3 = 0;
    reg [1:0] attack_state = 0;
   
    // pin bar attack
    wire FightBarPinOn;
    wire [11:0] fightbarpinout; 
    reg bar_pin_active=0;                      
    FightBarPin FightBarPinDisplay (.xx(x),.yy(y),.aactive(bar_pin_active), .is_in_state(is_fight),
                                  .FSpriteOn(FightBarPinOn),.dataout(fightbarpinout),.Pclk(CLK)); 

    // instantiate HpSprite code
    reg [8:0] decreaseHp = 0;
    wire HpSpriteOn; // 1=on, 0=off
    wire Hp1SpriteOn; // 1=on, 0=off
    wire Hp2SpriteOn; // 1=on, 0=off
    wire Hp3SpriteOn; // 1=on, 0=off
    wire [11:0] hpout; // pixel value
    wire [11:0] hp1out; // pixel value
    wire [11:0] hp2out; // pixel value
    wire [11:0] hp3out; // pixel value
    HpSprite HpDisplay (.xx(x),.yy(y),.aactive(is_avoid),.decreaseHp(decreaseHp),
                        .FSpriteOn(HpSpriteOn),.dataout(hpout),.Pclk(PixCLK));
              
    Hp1Sprite Hp1Display (.xx(x),.yy(y),.aactive(is_fight),
                          .FSpriteOn(Hp1SpriteOn),.dataout(hp1out),.Pclk(PixCLK),.totalhit(totalhit1));
    Hp2Sprite Hp2Display (.xx(x),.yy(y),.aactive(is_fight),
                          .FSpriteOn(Hp2SpriteOn),.dataout(hp2out),.Pclk(PixCLK),.totalhit(totalhit2));
    Hp3Sprite Hp3Display (.xx(x),.yy(y),.aactive(is_fight),
                          .FSpriteOn(Hp3SpriteOn),.dataout(hp3out),.Pclk(PixCLK),.totalhit(totalhit3));   
                          
    // instantiate AlienSprites code
    wire Alien1SpriteOn; // 1=on, 0=off
    wire Alien2SpriteOn; // 1=on, 0=off
    wire Alien3SpriteOn; // 1=on, 0=off
    wire [7:0] A1dout; // pixel value from Alien1.mem
    wire [7:0] A2dout; // pixel value from Alien2.mem
    wire [7:0] A3dout; // pixel value from Alien3.mem
    AlienSprites ADisplay (.xx(x),.yy(y),.aactive(is_fight),
                          .A1SpriteOn(Alien1SpriteOn),.A2SpriteOn(Alien2SpriteOn),
                          .A3SpriteOn(Alien3SpriteOn),.A1dataout(A1dout),
                          .A2dataout(A2dout),.A3dataout(A3dout),.Pclk(PixCLK));

    // display text
    wire alien1_txt, alien2_txt, alien3_txt;
    Pixel_On_Text2 #(.displayText("Alien C")) alien1(
                CLK,
                117, // text position.x (top left)
                125, // text position.y (top left)
                x, // current position.x
                y, // current position.y
                alien1_txt  // result, 1 if current pixel is on text, 0 otherwise
    );   
    Pixel_On_Text2 #(.displayText("Alien M")) alien2(
                CLK,
                285, // text position.x (top left)
                125, // text position.y (top left)
                x, // current position.x
                y, // current position.y
                alien2_txt  // result, 1 if current pixel is on text, 0 otherwise
    );  
    Pixel_On_Text2 #(.displayText("Alien Y")) alien3(
                CLK,
                456, // text position.x (top left)
                125, // text position.y (top left)
                x, // current position.x
                y, // current position.y
                alien3_txt  // result, 1 if current pixel is on text, 0 otherwise
    ); 
    
    wire end1_txt, end2_txt;
    Pixel_On_Text2 #(.displayText("YOU WIN!")) end1(
                CLK,
                281, // text position.x (top left)
                321, // text position.y (top left)
                x, // current position.x
                y, // current position.y
                end1_txt  // result, 1 if current pixel is on text, 0 otherwise
    );   
    Pixel_On_Text2 #(.displayText("YOU LOSE!")) end2(
                CLK,
                275, // text position.x (top left)
                114, // text position.y (top left)
                x, // current position.x
                y, // current position.y
                end2_txt  // result, 1 if current pixel is on text, 0 otherwise
    ); 
    
    wire title_txt, press_spacebar_txt;
    wire fname1_txt, fname2_txt, fname3_txt, fname4_txt, fname5_txt;
    wire lname1_txt, lname2_txt, lname3_txt, lname4_txt, lname5_txt;
    wire no1_txt, no2_txt, no3_txt, no4_txt, no5_txt;
    Pixel_On_Text2 #(.displayText("UNDERTALE-LIKE GAME")) title(
                CLK,
                230, // text position.x (top left)
                100, // text position.y (top left)
                x, // current position.x
                y, // current position.y
                title_txt  // result, 1 if current pixel is on text, 0 otherwise
    );   
    Pixel_On_Text2 #(.displayText("Press Spacebar")) press_spacebar(
                CLK,
                250, // text position.x (top left)
                360, // text position.y (top left)
                x, // current position.x
                y, // current position.y
                press_spacebar_txt  // result, 1 if current pixel is on text, 0 otherwise
    );
    Pixel_On_Text2 #(.displayText("Palinee")) fname1(
                CLK, 140, 180, x, y, fname1_txt);
    Pixel_On_Text2 #(.displayText("Pornapat")) fname2(
                CLK, 140, 205, x, y, fname2_txt);
    Pixel_On_Text2 #(.displayText("Vachirachat")) fname3(
                CLK, 140, 230, x, y, fname3_txt);
    Pixel_On_Text2 #(.displayText("Isaree")) fname4(
                CLK, 140, 255, x, y, fname4_txt);
    Pixel_On_Text2 #(.displayText("Warintorn")) fname5(
                CLK, 140, 280, x, y, fname5_txt);
    Pixel_On_Text2 #(.displayText("Setsiripaiboon")) lname1(
                CLK, 240, 180, x, y, lname1_txt);
    Pixel_On_Text2 #(.displayText("Sudjaipraparat")) lname2(
                CLK, 240, 205, x, y, lname2_txt);
    Pixel_On_Text2 #(.displayText("Sawaddiwat na ayuttaya")) lname3(
                CLK, 240, 230, x, y, lname3_txt);
    Pixel_On_Text2 #(.displayText("Jirapogchapone")) lname4(
                CLK, 240, 255, x, y, lname4_txt);
    Pixel_On_Text2 #(.displayText("Tantirittisak")) lname5(
                CLK, 240, 280, x, y, lname5_txt);
    Pixel_On_Text2 #(.displayText("6030373721")) no1(
                CLK, 425, 180, x, y, no1_txt);
    Pixel_On_Text2 #(.displayText("6030394921")) no2(
                CLK, 425, 205, x, y, no2_txt);
    Pixel_On_Text2 #(.displayText("6030506921")) no3(
                CLK, 425, 230, x, y, no3_txt);
    Pixel_On_Text2 #(.displayText("6030654021")) no4(
                CLK, 425, 255, x, y, no4_txt);
    Pixel_On_Text2 #(.displayText("6031053021")) no5(
                CLK, 425, 280, x, y, no5_txt);
       
    reg [8:0] barX = 307;
    always @(posedge PixCLK) begin
        if (time_count == 7) begin
            is_fight_done = 0;
        end
        act = 8'b00000000;
        if (RESET) begin
            tx_byte <= 8'h00;
            transmit <= 1'b0;
            rx_fifo_pop <= 1'b0;
        end else begin
            if (!rx_fifo_empty & !tx_fifo_full & !transmit /*& !is_transmitting*/) begin
               // w
               if(rx_byte == 8'b01110111) begin
                  act = 8'b00000001;
                  tx_byte <= 8'b01010111;
                  transmit <= 1'b1;
                  rx_fifo_pop <= 1'b1;
               end
               // a
               if(rx_byte == 8'b01100001) begin
                  act = 8'b00000010;
                  tx_byte <= 8'b01000001;
                  transmit <= 1'b1;
                  rx_fifo_pop <= 1'b1;
               end
               // s
               if(rx_byte == 8'b01110011) begin
                  act = 8'b00000100;
                  tx_byte <= 8'b01010011;
                  transmit <= 1'b1;
                  rx_fifo_pop <= 1'b1;
               end
               // d
               if(rx_byte == 8'b01100100) begin
                  act = 8'b00001000;
                  tx_byte <= 8'b01000100;
                  transmit <= 1'b1;
                  rx_fifo_pop <= 1'b1;
               end
               // c
               if(rx_byte == 8'b01100011) begin
                  if(totalhit1 < 100 && is_fight) begin
                     is_fight_done = 0;
                     attack_state = 1;
                     bar_pin_active = 1;
                  end              
                  else begin
                     bar_pin_active = 0;
                  end
                  tx_byte <= 8'b01000011;
                  transmit <= 1'b1;
                  rx_fifo_pop <= 1'b1;
               end
               // m
               if(rx_byte == 8'b01101101) begin
                  if(totalhit2 < 100 && is_fight) begin
                     is_fight_done = 0;
                     attack_state = 2;
                     bar_pin_active = 1;
                  end              
                  else begin
                     bar_pin_active = 0;
                  end
                  tx_byte <= 8'b01001101;
                  transmit <= 1'b1;
                  rx_fifo_pop <= 1'b1;
               end
               // y
               if(rx_byte == 8'b01111001) begin
                  if(totalhit3 < 100 && is_fight) begin
                     is_fight_done = 0;
                     attack_state = 3;
                     bar_pin_active = 1;
                  end              
                  else begin
                     bar_pin_active = 0;
                  end
                  tx_byte <= 8'b01011001;
                  transmit <= 1'b1;
                  rx_fifo_pop <= 1'b1;
               end
               // spacebar
               if(rx_byte == 8'b00100000) begin
                  if (start_state == 1) begin
                    start_game = 1;
                    totalhit1 = 0;
                    totalhit2 = 0;
                    totalhit3 = 0;
                    end_game = 0;
                  end
                  if (end_state == 1 || end_state == 2) begin
                    end_game = 1;
                    start_game = 0;    
                  end
                  if (is_fight && attack_state != 0) begin
                       bar_pin_active = ~ bar_pin_active;
                       case (attack_state) 
                            1 : begin totalhit1 = totalhit1 + damage; end
                            2 : begin totalhit2 = totalhit2 + damage; end
                            3 : begin totalhit3 = totalhit3 + damage; end
                       endcase
                       attack_state = 0;
                       is_fight_done = 1;
                  end 
                  tx_byte <= 8'b01011010;
                  transmit <= 1'b1;
                  rx_fifo_pop <= 1'b1;
               end
               else begin 
                  rx_fifo_pop <= 1'b1;
               end
            end else begin
               tx_byte <= 8'h00;
               transmit <= 1'b0;
               rx_fifo_pop <= 1'b0;
            end
        end // else: !if(RESET)
    end
    
    // change states    
    always @(posedge targetClk)
    begin
        if (start_state == 1 && start_game == 1) begin
            is_fight = 1;
            start_state = 0;
        end
        if ((end_state == 1 || end_state == 2) && end_game == 1) begin
            is_fight = 0;
            is_avoid = 0;
            start_state = 1;
            end_state = 0;
        end
        if (is_fight == 1 && totalhit1 >= 100 && totalhit2 >= 100 && totalhit3 >= 100) begin
            end_state = 1;
        end
        if (is_avoid == 1 && decreaseHp >= 200) begin
            end_state = 2;
        end
        if (is_fight == 1 && is_fight_done == 1 && end_state == 0) begin
            is_fight = 0;
            is_avoid = 1;
            time_count = 0;
        end
        if (is_avoid == 1 && end_state == 0) begin
            time_count = time_count +1;
        end
        if (is_avoid == 1 && time_count == 8 && end_state == 0) begin
            is_avoid = 0;
            is_fight = 1;
            time_count = 0;
        end
    end
    
    // instantiate HeartSprite code
    wire HeartSpriteOn; // 1=on, 0=off
    wire [7:0] dout; // pixel value
    HeartSprite #(.stepX(2), . stepY(3), .autoplay(1)) HeartDisplay (.xx(x),.yy(y),.aactive(is_avoid),
                                                                     .BSpriteOn(HeartSpriteOn),.dataout(dout),.BR(btnR),
                                                                     .BL(btnL),.Pclk(PixCLK),.action(act));
      
    // instantiate FrameSprite code
    wire FrameSpriteOn; // 1=on, 0=off
    wire [11:0] fout; // pixel value
    FrameSprite FrameDisplay (.xx(x),.yy(y),.aactive(is_avoid),
                              .FSpriteOn(FrameSpriteOn),.dataout(fout),.Pclk(PixCLK));
    
    // instantiate HpFrameSprite code
    wire HpFrameSpriteOn; // 1=on, 0=off
    wire HpFrame1SpriteOn; // 1=on, 0=off
    wire HpFrame2SpriteOn; // 1=on, 0=off
    wire HpFrame3SpriteOn; // 1=on, 0=off
    wire [11:0] hpfout; // pixel value
    wire [11:0] hpf1out; // pixel value
    wire [11:0] hpf2out; // pixel value
    wire [11:0] hpf3out; // pixel value
    HpFrameSprite HpFrameDisplay (.xx(x),.yy(y),.aactive(is_avoid),
                                  .FSpriteOn(HpFrameSpriteOn),.dataout(hpfout),.Pclk(PixCLK));
    HpFrame1Sprite HpFrame1Display (.xx(x),.yy(y),.aactive(is_fight),
                                    .FSpriteOn(HpFrame1SpriteOn),.dataout(hpf1out),.Pclk(PixCLK));
    HpFrame2Sprite HpFrame2Display (.xx(x),.yy(y),.aactive(is_fight),
                                    .FSpriteOn(HpFrame2SpriteOn),.dataout(hpf2out),.Pclk(PixCLK));
    HpFrame3Sprite HpFrame3Display (.xx(x),.yy(y),.aactive(is_fight),
                                    .FSpriteOn(HpFrame3SpriteOn),.dataout(hpf3out),.Pclk(PixCLK));
                                     
    // instantiate FightBarSprite code
    wire [1:0] FightBarSpriteOn; // 1,2,3=on(red,orange,yellow), 0=off
    wire [11:0] fightbarout; // pixel value
    FightBarSprite FightBarDisplay (.xx(x),.yy(y),.aactive(is_fight),
                                    .FSpriteOn(FightBarSpriteOn),.dataout(fightbarout),.Pclk(PixCLK));
     
    // instantiate BulletSprites code
    reg not_collided_1 = 1;
    reg not_collided_2 = 1;
    reg not_collided_3 = 1;
    wire Bullet1SpriteOn; // 1=on, 0=off
    wire Bullet2SpriteOn; // 1=on, 0=off
    wire Bullet3SpriteOn; // 1=on, 0=off
    wire [11:0] bullet1out; // pixel value
    wire [11:0] bullet2out; // pixel value
    wire [11:0] bullet3out; // pixel value
    Bullet1Sprite #(.stepX(1), .stepY(1), .autoplay(1)) Bullet1Display (.xx(x),.yy(y),.aactive((is_avoid && not_collided_1)),
                                  .BulletSpriteOn(Bullet1SpriteOn),.dataout(bullet1out),.Pclk(PixCLK));
    Bullet2Sprite #(.stepX(1), .stepY(3), .autoplay(1)) Bullet2Display (.xx(x),.yy(y),.aactive((is_avoid && not_collided_2)),
                                  .BulletSpriteOn(Bullet2SpriteOn),.dataout(bullet2out),.Pclk(PixCLK));
    Bullet3Sprite #(.stepX(1), .stepY(2), .autoplay(1)) Bullet3Display (.xx(x),.yy(y),.aactive((is_avoid && not_collided_3)),
                                  .BulletSpriteOn(Bullet3SpriteOn),.dataout(bullet3out),.Pclk(PixCLK));              
                                  
    // load colour palette
    reg [7:0] palette [0:191]; // 8 bit values from the 192 hex entries in the colour palette
    reg [7:0] COL = 0; // background colour palette value
    initial begin
        $readmemh("pal24bit.mem", palette); // load 192 hex values into "palette"
    end
    
    // draw on the active area of the screen
    always @ (posedge PixCLK)
    begin
        if (active)
            begin
                if (HeartSpriteOn==1 && is_avoid)
                    begin
                        RED <= (palette[(dout*3)])>>4; 
                        GREEN <= (palette[(dout*3)+1])>>4; 
                        BLUE <= (palette[(dout*3)+2])>>4; 
                    end
                else
                if (Alien1SpriteOn==1 && is_fight)
                    begin
                        RED <= (palette[(A1dout*3)])>>4; 
                        GREEN <= (palette[(A1dout*3)+1])>>4; 
                        BLUE <= (palette[(A1dout*3)+2])>>4; 
                    end
                else
                if (Alien2SpriteOn==1 && is_fight)
                    begin
                        RED <= (palette[(A2dout*3)])>>4; 
                        GREEN <= (palette[(A2dout*3)+1])>>4; 
                        BLUE <= (palette[(A2dout*3)+2])>>4;
                    end
                else
                if (Alien3SpriteOn==1 && is_fight)
                    begin
                        RED <= (palette[(A3dout*3)])>>4; 
                        GREEN <= (palette[(A3dout*3)+1])>>4; 
                        BLUE <= (palette[(A3dout*3)+2])>>4; 
                    end
                else
                if (FrameSpriteOn==1 && is_avoid)
                    begin
                        RED <= fout[11:8];
                        GREEN <= fout[7:4];
                        BLUE <= fout[3:0];
                    end
                else
                if (HpFrameSpriteOn==1 && is_avoid)
                    begin
                        RED <= hpfout[11:8];
                        GREEN <= hpfout[7:4];
                        BLUE <= hpfout[3:0];
                    end
                else
                if (HpFrame1SpriteOn==1 && is_fight)
                    begin
                        RED <= hpf1out[11:8];
                        GREEN <= hpf1out[7:4];
                        BLUE <= hpf1out[3:0];
                    end
                else
                if (HpFrame2SpriteOn==1 && is_fight)
                    begin
                        RED <= hpf2out[11:8];
                        GREEN <= hpf2out[7:4];
                        BLUE <= hpf2out[3:0];
                    end
                else
                if (HpFrame3SpriteOn==1 && is_fight)
                    begin
                        RED <= hpf3out[11:8];
                        GREEN <= hpf3out[7:4];
                        BLUE <= hpf3out[3:0];
                    end
                else
                if (HpSpriteOn==1 && is_avoid)
                    begin
                        RED <= hpout[11:8];
                        GREEN <= hpout[7:4];
                        BLUE <= hpout[3:0];
                    end
                else
                if (Hp1SpriteOn==1 && is_fight)
                    begin
                        RED <= hp1out[11:8];
                        GREEN <= hp1out[7:4];
                        BLUE <= hp1out[3:0];
                    end
                else
                if (Hp2SpriteOn==1 && is_fight)
                    begin
                        RED <= hp2out[11:8];
                        GREEN <= hp2out[7:4];
                        BLUE <= hp2out[3:0];
                    end
                else
                if (Hp3SpriteOn==1 && is_fight)
                    begin
                        RED <= hp3out[11:8];
                        GREEN <= hp3out[7:4];
                        BLUE <= hp3out[3:0];
                    end
                else
                if ((FightBarSpriteOn==1 || FightBarSpriteOn==2 || FightBarSpriteOn==3) && is_fight)
                    begin
                        RED <= fightbarout[11:8];
                        GREEN <= fightbarout[7:4];
                        BLUE <= fightbarout[3:0];
                    end
                else
                if (Bullet1SpriteOn==1 && is_avoid)
                    begin
                        RED <= bullet1out[11:8];
                        GREEN <= bullet1out[7:4];
                        BLUE <= bullet1out[3:0];
                    end
                else
                if (Bullet2SpriteOn==1 && is_avoid)
                    begin
                        RED <= bullet2out[11:8];
                        GREEN <= bullet2out[7:4];
                        BLUE <= bullet2out[3:0];
                    end
                else
                if (Bullet3SpriteOn==1 && is_avoid)
                    begin
                        RED <= bullet3out[11:8];
                        GREEN <= bullet3out[7:4];
                        BLUE <= bullet3out[3:0];
                    end
                else
                    begin
                        RED <= 0; 
                        GREEN <= 0; 
                        BLUE <= 0; 
                    end
                if (FightBarPinOn == 1)
                    begin
                        RED <= fightbarpinout[11:8];
                        GREEN <= fightbarpinout[7:4];
                        BLUE <= fightbarpinout[3:0];                        
                    end    
                if (alien1_txt && is_fight && attack_state == 1) begin
                    RED <= 15;
                    GREEN <= 11;
                    BLUE <= 12;
                end
                else 
                if (alien2_txt && is_fight && attack_state == 2) begin
                    RED <= 15;
                    GREEN <= 11;
                    BLUE <= 12;
                end
                else 
                if (alien3_txt && is_fight && attack_state == 3) begin
                    RED <= 15;
                    GREEN <= 11;
                    BLUE <= 12;
                end
                else 
                if ((alien1_txt || alien2_txt || alien3_txt) && is_fight) begin
                    RED <= 15;
                    GREEN <= 15;
                    BLUE <= 15;
                end  
                else
                if (end_state==1 && end1_txt) begin
                    RED <= 15;
                    GREEN <= 15;
                    BLUE <= 15;
                end
                else
                if (end_state==2 && end2_txt) begin
                    RED <= 15;
                    GREEN <= 15;
                    BLUE <= 15;
                end
                else
                if (start_state && (title_txt || press_spacebar_txt)) begin
                    RED <= 15;
                    GREEN <= 15;
                    BLUE <= 15;
                end
                else
                if (start_state && (fname1_txt || fname2_txt || fname3_txt || fname4_txt || fname5_txt)) begin
                    RED <= 15;
                    GREEN <= 15;
                    BLUE <= 15;
                end
                else
                if (start_state && (lname1_txt || lname2_txt || lname3_txt || lname4_txt || lname5_txt)) begin
                    RED <= 15;
                    GREEN <= 15;
                    BLUE <= 15;
                end
                else
                if (start_state && (no1_txt || no2_txt || no3_txt || no4_txt || no5_txt)) begin
                    RED <= 15;
                    GREEN <= 15;
                    BLUE <= 15;
                end
                
                // reset game
                if (start_state) begin
                    decreaseHp = 0;
                    not_collided_1 = 0;
                    not_collided_2 = 0;
                    not_collided_3 = 0;
                end
                
                // heart & bullet
                if (HeartSpriteOn==1 && Bullet1SpriteOn==1 && is_avoid)
                    begin
                        not_collided_1 = 0; 
                        decreaseHp = decreaseHp+10;
                    end
                if (HeartSpriteOn==1 && Bullet2SpriteOn==1 && is_avoid)
                    begin
                        not_collided_2 = 0; 
                        decreaseHp = decreaseHp+15;
                    end
                if (HeartSpriteOn==1 && Bullet3SpriteOn==1 && is_avoid)
                    begin
                        not_collided_3 = 0; 
                        decreaseHp = decreaseHp+25;
                    end    
                if (is_fight)
                    begin
                        if (totalhit1 < 100)
                            not_collided_1 = 1;
                        if (totalhit2 < 100)
                            not_collided_2 = 1;
                        if (totalhit3 < 100)
                            not_collided_3 = 1;
                        if (totalhit1 >= 100)
                            not_collided_1 = 0;
                        if (totalhit2 >= 100)
                            not_collided_2 = 0;
                        if (totalhit3 >= 100)
                            not_collided_3 = 0;
                    end
                    
                // attack alien!!
                if (FightBarSpriteOn==1 && FightBarPinOn==1)
                    begin
                        damage = 45;
                    end
                else
                if (FightBarSpriteOn==2 && FightBarPinOn==1)
                    begin
                        damage = 25;
                    end
                else
                if (FightBarSpriteOn==3 && FightBarPinOn==1)
                    begin
                        damage = 10;
                    end
                         
            end
        else
                begin
                    RED <= 0; // set RED, GREEN & BLUE
                    GREEN <= 0; // to "0" when x,y outside of
                    BLUE <= 0; // the active display area
                end
    end
    
endmodule

module clkDiv(
    output clkDiv,
    input clk
    );
    
    reg clkDiv;
    
    initial begin
        clkDiv = 0;
    end
    
    always @(posedge clk) begin
        clkDiv = ~clkDiv;
    end
endmodule