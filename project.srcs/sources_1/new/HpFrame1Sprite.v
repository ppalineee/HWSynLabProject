`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.05.2020 02:42:57
// Design Name: 
// Module Name: HpFrame1Sprite
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


module HpFrame1Sprite(
    input wire [9:0] xx, // current x position
    input wire [9:0] yy, // current y position
    input wire aactive, // high during active pixel drawing
    output reg FSpriteOn, // 1=on, 0=off
    output wire [11:0] dataout, // pixel value
    input wire Pclk // 25MHz pixel clock
    );
	
	reg [11:0] rgb; 
	reg [11:0] cyan = 12'b000011111111;
	reg [11:0] magenta = 12'b111100001111;
	reg [11:0] yellow = 12'b111111110000;
	reg [11:0] white = 12'hFFF;
          
    // setup character positions and sizes
    reg [8:0] FrameX = 142;
    reg [8:0] FrameY = 30; 
    localparam FrameWidth = 50; 
    localparam FrameHeight = 7; 
    
    always @ (posedge Pclk)
    begin 
        if (aactive)
            begin 
                if (xx==FrameX+FrameWidth && yy<FrameY+FrameHeight && yy>FrameY-FrameHeight)
                    begin
                        rgb <= cyan;
                        FSpriteOn <=1;
                    end
                else
                if  (xx==FrameX-FrameWidth && yy<FrameY+FrameHeight && yy>FrameY-FrameHeight)
                    begin
                        rgb <= cyan;
                        FSpriteOn <=1;
                    end
                else
                if (xx<FrameX+FrameWidth && xx>FrameX-FrameWidth && yy==FrameY+FrameHeight)
                    begin
                        rgb <= cyan;
                        FSpriteOn <=1;
                    end
                else
                if (xx<FrameX+FrameWidth && xx>FrameX-FrameWidth && yy==FrameY-FrameHeight)
                    begin
                        rgb <= cyan;
                        FSpriteOn <=1;
                    end
                else
                    FSpriteOn <=0;
            end
    end
    
    assign dataout = rgb;
    
endmodule
