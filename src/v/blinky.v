`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/13/2025 08:28:21 AM
// Design Name: 
// Module Name: blinky
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


module blinky(
    output LED0,
    input clk
    );
 
reg blink;
initial blink = 0;

reg counter = 8'b0;

assign LED0 = blink;

always @(posedge clk)
begin
    counter = counter + 1;
end

always @(posedge clk)
begin
    if (counter == 0) blink = ~blink;
end

endmodule
