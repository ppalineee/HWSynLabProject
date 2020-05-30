//--------------------------------------------------
// HeartSprite Module : Digilent Basys 3               
// BeeInvaders Tutorial 3 : Onboard clock 100MHz
// VGA Resolution 640x480 @ 60Hz : Pixel Clock 25MHz
//--------------------------------------------------
`timescale 1ns / 1ps

// Setup HeartSprite Module
module HeartSprite #(
      stepX = 1,
      stepY = 1,
      autoplay = 0
    )
    (
    input wire [9:0] xx, // current x position
    input wire [9:0] yy, // current y position
    input wire aactive, // high during active pixel drawing
    output reg BSpriteOn, // 1=on, 0=off
    output wire [7:0] dataout, // 8 bit pixel value from heart.mem
    input wire BR, // right button
    input wire BL, // left button
    input wire Pclk, // 25MHz pixel clock
    input wire [7:0] action
    );

    // instantiate HeartRom code
    reg [9:0] address; // 2^10 or 1024, need 34 x 27 = 918
    HeartRom HeartVRom (.i_addr(address),.i_clk2(Pclk),.o_data(dataout));
            
    // setup character positions and sizes
    reg [9:0] HeartX = 297; // Heart X start position
    reg [8:0] HeartY = 330; // Heart Y start position
    localparam HeartWidth = 22; // Heart width in pixels
    localparam HeartHeight = 20; // Heart height in pixels
    
    reg [2:0] step_x = stepX ;
    reg [2:0] step_y = stepY;  
    reg direction_x = 1;
    reg direction_y = 1;
    reg [21:0] count = 0;
    reg [10:0] times = 0;
    
    always @ (posedge Pclk)
    begin
//        count = count + 1;
        // W -- go up
        if (action == 1 && HeartY>277) 
            HeartY<=HeartY-step_y;  
        // A -- go to the left
        if (action == 2 && HeartX>243) 
            HeartX<=HeartX-step_x;   
        // S -- go down
        if (action == 4 && HeartY<384) 
            HeartY<=HeartY+step_y; 
        // D -- go to the right
        if (action == 8 && HeartX<349) 
            HeartX<=HeartX+step_x; 
//        if (count == 500000) begin
//            count = 0;
//            times = times + 1;
//        end
         
//        // control direction 
//        case (times) 
//            200 : begin direction_x=0; direction_y=1; end
//            400 : begin direction_x=0; direction_y=0; end
//            600 : begin direction_x=1; direction_y=0; end
//            800 : begin direction_x=1; direction_y=1; end
//        endcase

//        // reset times
//        if (times == 800) begin
//            times = 0;
//        end
         
//        // move heart along direction_x and direction_y
//        if (autoplay == 1 && count == 0) begin
//            case ({direction_x,direction_y}) 
//                2'b00 : begin HeartX<=HeartX-step_x; HeartY<=HeartY+step_y; end
//                2'b01 : begin HeartX<=HeartX-step_x; HeartY<=HeartY-step_y; end
//                2'b10 : begin HeartX<=HeartX+step_x; HeartY<=HeartY+step_y; end
//                2'b11 : begin HeartX<=HeartX+step_x; HeartY<=HeartY-step_y; end
//            endcase
//        end
         
//        if (xx==639 && yy==479)
//            begin // check for left or right button pressed
//                if (BR == 1 && HeartX<640-HeartWidth)
//                    HeartX<=HeartX+1;
//                if (BL == 1 && HeartX>1)
//                    HeartX<=HearaaaaaatX-1;
//            end    
        if (aactive)
            begin // check if xx,yy are within the confines of the Heart character
                if (xx==HeartX-1 && yy==HeartY)
                    begin
                        address <= 0;
                        BSpriteOn <=1;
                    end
                if ((xx>HeartX-1) && (xx<HeartX+HeartWidth) && (yy>HeartY-1) && (yy<HeartY+HeartHeight))
                    begin
                        address <= address + 1;
                        BSpriteOn <=1;
                    end
                else
                    BSpriteOn <=0;
            end
    end
    
endmodule