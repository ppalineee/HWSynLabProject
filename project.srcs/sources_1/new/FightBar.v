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


module FightBarSprite(
    input wire [9:0] xx, // current x position
    input wire [9:0] yy, // current y position
    input wire aactive, // high during active pixel drawing
    output reg [1:0] FSpriteOn, // 1=on, 0=off
    output wire [11:0] dataout, // pixel value
    input wire Pclk // 25MHz pixel clock
    );
	
	reg [11:0] rgb; 
	reg [11:0] yellow = 12'b111111110000;
	reg [11:0] orange = 12'b111110000000;
	reg [11:0] red = 12'hF00;
          
    // setup character positions and sizes
    reg [8:0] FrameX = 307;
    reg [8:0] FrameY = 215;  
    localparam FrameHeight = 30; 
    
    always @ (posedge Pclk)
    begin 
        if (aactive)
            begin 
                // red
                if (xx<=FrameX+15 && xx>=FrameX-15 && yy<FrameY+FrameHeight && yy>FrameY-FrameHeight)
                    begin
                        rgb <= red;
                        FSpriteOn <=1;
                    end
                else
                // orange
                if  (xx<FrameX-15 && xx>=FrameX-55 && yy<FrameY+FrameHeight && yy>FrameY-FrameHeight)
                    begin
                        rgb <= orange;
                        FSpriteOn <=2;
                    end
                else
                if  (xx<=FrameX+55 && xx>FrameX+15 && yy<FrameY+FrameHeight && yy>FrameY-FrameHeight)
                    begin
                        rgb <= orange;
                        FSpriteOn <=2;
                    end
                else
                // yellow
                if (xx<FrameX-55 && xx>FrameX-105 && yy<FrameY+FrameHeight && yy>FrameY-FrameHeight)
                    begin
                        rgb <= yellow;
                        FSpriteOn <=3;
                    end
                else
                if (xx<FrameX+105 && xx>FrameX+55 && yy<FrameY+FrameHeight && yy>FrameY-FrameHeight)
                    begin
                        rgb <= yellow;
                        FSpriteOn <=3;
                    end
                else
                    FSpriteOn <=0;
            end
    end
    
    assign dataout = rgb;
    
endmodule