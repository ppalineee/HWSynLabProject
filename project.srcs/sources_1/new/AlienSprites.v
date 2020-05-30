//--------------------------------------------------
// AlienSprites Module : Digilent Basys 3               
// BeeInvaders Tutorial 3 : Onboard clock 100MHz
// VGA Resolution 640x480 @ 60Hz : Pixel Clock 25MHz
//--------------------------------------------------
`timescale 1ns / 1ps

// Setup AlienSprites Module
module AlienSprites(
    input wire [9:0] xx, // current x position
    input wire [9:0] yy, // current y position
    input wire aactive, // high during active pixel drawing
    output reg A1SpriteOn, // 1=on, 0=off
    output reg A2SpriteOn, // 1=on, 0=off
    output reg A3SpriteOn, // 1=on, 0=off
    output wire [7:0] A1dataout, // 8 bit pixel value from Alien1.mem
    output wire [7:0] A2dataout, // 8 bit pixel value from Alien2.mem
    output wire [7:0] A3dataout, // 8 bit pixel value from Alien3.mem
    input wire Pclk // 25MHz pixel clock
    );

// instantiate Alien1Rom code
    reg [9:0] A1address; // 2^10 or 1024, need 31 x 26 = 806
    Alien1Rom Alien1VRom (.i_A1addr(A1address),.i_clk2(Pclk),.o_A1data(A1dataout));

// instantiate Alien2Rom code
    reg [9:0] A2address; // 2^10 or 1024, need 31 x 21 = 651
    Alien2Rom Alien2VRom (.i_A2addr(A2address),.i_clk2(Pclk),.o_A2data(A2dataout));

// instantiate Alien3Rom code
    reg [9:0] A3address; // 2^10 or 1024, need 31 x 27 = 837
    Alien3Rom Alien3VRom (.i_A3addr(A3address),.i_clk2(Pclk),.o_A3data(A3dataout));

// setup character positions and sizes
    reg [9:0] A1X = 120; // Alien1 X start position
    reg [9:0] A1Y = 70; // Alien1 Y start position
    localparam A1Width = 45; // Alien1 width in pixels
    localparam A1Height = 30; // Alien1 height in pixels
    reg [9:0] A2X = 287; // Alien2 X start position
    reg [9:0] A2Y = 70; // Alien2 Y start position
    localparam A2Width = 50; // Alien2 width in pixels
    localparam A2Height = 42; // Alien2 height in pixels
    reg [9:0] A3X = 454; // Alien3 X start position
    reg [9:0] A3Y = 70; // Alien3 Y start position
    localparam A3Width = 60; // Alien3 width in pixels
    localparam A3Height = 42; // Alien3 height in pixels

    always @ (posedge Pclk)
    begin
        if (aactive)
            begin 
                // check if xx,yy are within the confines of the Alien characters
                // Alien1
                if (xx==A1X-1 && yy==A1Y)
                    begin
                        A1address <= 0;
                        A1SpriteOn <=1;
                    end                   
                if ((xx>A1X-1) && (xx<A1X+A1Width) && (yy>A1Y-1) && (yy<A1Y+A1Height))   
                    begin
                        A1address <= A1address + 1;
                        A1SpriteOn <=1;
                    end
                else
                    A1SpriteOn <=0;
                   
                    
                // Alien2    
                if (xx==A2X-1 && yy==A2Y)
                    begin
                        A2address <= 0;
                        A2SpriteOn <=1;
                    end
                if ((xx>A2X-1) && (xx<A2X+A2Width) && (yy>A2Y-1) && (yy<A2Y+A2Height))
                    begin
                        A2address <= A2address + 1;
                        A2SpriteOn <=1;
                    end
                else
                    A2SpriteOn <=0;
                    
                // Alien3
                if (xx==A3X-1 && yy==A3Y)
                    begin
                        A3address <= 0;
                        A3SpriteOn <=1;
                    end
                if ((xx>A3X-1) && (xx<A3X+A3Width) && (yy>A3Y-1) && (yy<A3Y+A3Height))
                    begin
                        A3address <= A3address + 1;
                        A3SpriteOn <=1;
                    end
                else
                    A3SpriteOn <=0;
            end
    end
endmodule
