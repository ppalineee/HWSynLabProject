`timescale 1ns / 1ps

module Bullet1Sprite #(
      stepX = 1,
      stepY = 1,
      autoplay = 0
    )
    ( 
    input wire [9:0] xx, // current x position
    input wire [9:0] yy, // current y position
    input wire aactive, // high during active pixel drawing
    output reg BulletSpriteOn, // 1=on, 0=off
    output wire [11:0] dataout, // pixel value
    input wire Pclk // 25MHz pixel clock
    );

	reg [11:0] rgb; 
	reg [11:0] cyan = 12'b000011111111;
	reg [11:0] magenta = 12'b111100001111;
	reg [11:0] yellow = 12'b111111110000;
            
    // setup character positions and sizes
    reg [8:0] BulletX = 255; 
    reg [8:0] BulletY = 275;
    localparam BulletRadius = 3;
    
    reg [2:0] step_x = stepX ;
    reg [2:0] step_y = stepY;  
    reg direction_x = 1;
    reg direction_y = 0;
    reg [21:0] count = 0;
    
    localparam upperbound = 278;
    localparam lowerbound = 401;
    localparam leftbound = 245;
    localparam rightbound = 369;
    
    always @ (posedge Pclk)
    begin
        count = count + 1;
        if (count == 650000) begin
            count = 0;
        end
        
        // move bullet along direction_x and direction_y
        if (autoplay == 1 && count == 0) begin
            case ({direction_x,direction_y}) 
                2'b00 : begin 
                    BulletX<=BulletX-step_x; 
                    BulletY<=BulletY+step_y;
                    if (BulletX<=leftbound) begin direction_x=1; direction_y=0; end
                    if (BulletY>=lowerbound) begin direction_x=0; direction_y=1; end
                end
                2'b01 : begin 
                    BulletX<=BulletX-step_x; 
                    BulletY<=BulletY-step_y;
                    if (BulletX<=leftbound) begin direction_x=1; direction_y=1; end
                    if (BulletY<=upperbound) begin direction_x=0; direction_y=0; end
                end
                2'b10 : begin 
                    BulletX<=BulletX+step_x; 
                    BulletY<=BulletY+step_y; 
                    if (BulletX>=rightbound) begin direction_x=0; direction_y=0; end
                    if (BulletY>=lowerbound) begin direction_x=1; direction_y=1; end
                end
                2'b11 : begin 
                    BulletX<=BulletX+step_x; 
                    BulletY<=BulletY-step_y; 
                    if (BulletX>=rightbound) begin direction_x=0; direction_y=1; end
                    if (BulletY<=upperbound) begin direction_x=1; direction_y=0; end 
                end
            endcase
        end
 
        if (aactive)
            begin 
                if ((xx-BulletX)*(xx-BulletX)+(yy-BulletY)*(yy-BulletY)<=(BulletRadius*BulletRadius))
                    begin
                        rgb <= cyan;
                        BulletSpriteOn <=1;
                    end
                else
                    BulletSpriteOn <=0;
            end
        else
            BulletSpriteOn <=0;
    end
    
    assign dataout = rgb;
    
endmodule
