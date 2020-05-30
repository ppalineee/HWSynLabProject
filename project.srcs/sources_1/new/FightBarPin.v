`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.05.2020 02:42:57
// Design Name: 
// Module Name: FightBarSprite
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FightBarPin #(
      stepX = 1,
      stepY = 0,
      autoplay = 1
    )
    (
    input wire [9:0] xx, // current x position
    input wire [9:0] yy, // current y position
    input wire aactive, // high during active pixel drawing
    input wire is_in_state,
    output reg FSpriteOn, // 1=on, 0=off
    output wire [11:0] dataout, // pixel value
    input wire Pclk // 25MHz pixel clock
    );
	
	reg [11:0] rgb; 
	reg [11:0] white = 12'b111111111111;
	reg [11:0] black = 12'h00;
    
    // setup character positions and sizes
    reg [8:0] FrameX = 307;
    reg [8:0] FrameY = 215; 
    localparam FrameWidth = 3; 
    localparam FrameHeight = 35; 
    reg [2:0] step_x = stepX ;
    reg [2:0] step_y = stepY;  
    reg direction_x = 1;
    // make move not so fast
    reg [21:0] count = 0;

    always @ (posedge Pclk)
    begin 
        if (aactive && is_in_state)
            begin 
                // control direction 
                if(FrameX <= 307-105) begin
                    direction_x = 1;
                end
                if(FrameX >= 307+105) begin 
                    direction_x = 0;
                end
                
                // move pin along direction_x and direction_y
                if (autoplay == 1 && count == 0) begin
                    case ({direction_x}) 
                        1 : begin FrameX<=FrameX+step_x; end
                        0 : begin FrameX<=FrameX-step_x; end
                    endcase
                end       
                
               // count to move pixel
               count = count + 1;
               if (count == 400000) begin
                    count = 0;
                end               
            end
            
        if (xx<=FrameX+FrameWidth && xx>=FrameX-FrameWidth && yy<FrameY+FrameHeight && yy>FrameY-FrameHeight && is_in_state == 1)
           begin
            rgb <= white;
            FSpriteOn <=1;
           end
        else
        begin
           FSpriteOn <=0;
        end    
    end

    assign dataout = rgb;
    
endmodule