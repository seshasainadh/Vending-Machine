`timescale 1us/1ns
module vend_tb ;
  reg clk; reg btnC,btnR,btnL; reg [7:0] sw; wire [7:0] led; wire [6:0] seg; wire [3:0] an;

  vending_machine_topmodule dut0 (clk,btnC,btnR,btnL,sw,led,seg,an);

  always #20 clk = ~clk ;
  initial begin
    $dumpvars();
    clk = 0 ; btnC = 0 ; btnR = 0 ; btnL = 0 ; sw = 0 ;
    #1000 sw = 8'h04 ;
    #500 btnC = 1 ;
    #100 btnC = 0 ;
    #1000 $finish ;
  end
  initial begin
    #102 btnL = 1 ; #100 btnL = 0 ; #400 btnL = 1 ; #100 btnL = 0 ; #600 btnL = 1 ; #100 btnL = 0 ; 
  end 
  initial begin
    #152 btnR = 1 ; #100 btnR = 0 ; #400 btnR = 1 ; #100 btnR = 0 ; #600 btnR = 1 ; #100 btnR = 0 ; 
  end 
endmodule 


module vending_machine_topmodule(clk,btnC,btnR,btnL,sw,led,seg,an);
  input clk;
  input btnC,btnR,btnL;
  input [7:0] sw;
  output [7:0] led;
  output [6:0] seg;
  output [3:0] an;

  wire [11:0] money;
  wire btnCclk,btnLclr,btnRclr;

  wire [3:0] thos,huns,tens,ones;

  binarytoBCD bcd1(money,thos,huns,tens,ones);

  sevenseg_driver seg1( .clk(clk), .clr(1'b0), .in1(thos), 
                        .in2(huns), .in3(tens), .in4(ones), .seg(seg), .an(an));
    
  vending_machine vm( .clk(clk), .coin1(btnR), .coin2(btnL), .select(sw[3:0]), .buy(btnC),
                      .load(sw[7:4]), .money(money), .products(led[3:0]), .outofstock(led[7:4]));
endmodule


module vending_machine(clk,coin1,coin2,select,buy,load,money,products,outofstock);

  input clk;
  input coin1; //25 cents
  input coin2; //1 dollar (100 cents)
  input [3:0] select;
  input buy;
  input [3:0] load;
  output reg [11:0] money=0;
  output reg [3:0] products=0;
  output reg [3:0] outofstock=0;

  reg coin1_prev,coin2_prev;
  reg buy_prev;

  reg [3:0] stock1=4'b1010;
  reg [3:0] stock2=4'b1010;
  reg [3:0] stock3=4'b1010;
  reg [3:0] stock4=4'b1010;

  always @ (posedge clk) begin
    coin1_prev <= coin1; coin2_prev <= coin2; buy_prev <= buy;

    if (coin1_prev == 1'b0 && coin1 == 1'b1) money <= money + 12'd25;
    else if (coin2_prev == 1'b0 && coin2 == 1'b1) money <= money + 12'd100;
    else if (buy_prev == 1'b0 && buy == 1'b1)  begin
      case (select)
        4'b0001: 
          if (money >= 12'd25 && stock1 > 0) begin
	    products[0] <= 1'b1; stock1 <= stock1 - 1'b1; money <= money - 12'd25;
	  end
        4'b0010:
          if (money >= 12'd75 && stock2 > 0) begin
            products[1] <= 1'b1; stock2 <= stock2 - 1'b1; money <= money - 12'd75;
          end
        4'b0100:
          if (money >= 12'd150 && stock3 > 0) begin
            products[2] <= 1'b1; stock3 <= stock3 - 1'b1; money <= money - 12'd150;
          end
        4'b1000:
          if (money >= 12'd200 && stock4 > 0) begin
            products[3] <= 1'b1; stock4 <= stock4 - 1'b1; money <= money - 12'd200;
          end
      endcase
    end

    else if (buy_prev == 1'b1 && buy == 1'b0) begin
      products[0] <= 1'b0; products[1] <= 1'b0; products[2] <= 1'b0;    products[3] <= 1'b0;
    end

    else begin
      if (stock1 == 4'b0) outofstock[0] <= 1'b1; else outofstock[0] <= 1'b0;
      if (stock2 == 4'b0) outofstock[1] <= 1'b1; else outofstock[1] <= 1'b0;
      if (stock3 == 4'b0) outofstock[2] <= 1'b1; else outofstock[2] <= 1'b0;
      if (stock4 == 4'b0) outofstock[3] <= 1'b1; else outofstock[3] <= 1'b0;

      case (load)
        4'b0001: stock1 <= 4'b1111;
        4'b0010: stock2 <= 4'b1111;
        4'b0100: stock3 <= 4'b1111;
        4'b1000: stock4 <= 4'b1111;
      endcase
    end
  end

endmodule


module binarytoBCD(binary,thos,huns,tens,ones);

  input [11:0] binary;
  output reg [3:0] thos, huns, tens, ones;

  reg [11:0] bcd_data=0;

  always @ (binary) begin
    bcd_data = binary;
    thos = bcd_data / 1000;
    bcd_data = bcd_data % 1000;
    huns = bcd_data / 100;
    bcd_data = bcd_data % 100;
    tens = bcd_data / 10;
    ones = bcd_data % 10;
  end

endmodule


module sevenseg_driver(clk,clr,in1,in2,in3,in4,seg,an);

  input clk;
  input clr;
  input [3:0] in1, in2, in3, in4;
  output reg [6:0] seg = 7'b0;
  output reg [3:0] an = 4'b0;

  wire [6:0] seg1, seg2, seg3, seg4;
  reg [12:0] segclk = 12'b0;

  localparam LEFT = 2'b00, MIDLEFT = 2'b01, MIDRIGHT = 2'b10, RIGHT = 2'b11;
  reg [1:0] state=LEFT;

  decoder_7seg disp1(in1,seg1);
  decoder_7seg disp2(in2,seg2);
  decoder_7seg disp3(in3,seg3);
  decoder_7seg disp4(in4,seg4);
    
  always @ (posedge clk) segclk <= segclk + 1'b1;

  always @(posedge segclk[2] or posedge clr) begin
    if (clr == 1) begin
      seg <= 7'b0000000;
      an <= 4'b0000;
      state <= LEFT;
    end
    else begin
      case(state)
        LEFT: begin seg <= seg1; an <= 4'b0111; state <= MIDLEFT; end
        MIDLEFT: begin seg <= seg2; an <= 4'b1011; state <= MIDRIGHT; end
        MIDRIGHT: begin seg <= seg3; an <= 4'b1101; state <= RIGHT; end
        RIGHT: begin seg <= seg4; an <= 4'b1110; state <= LEFT; end
      endcase
    end
  end
endmodule


module decoder_7seg(in1,out1);

  input [3:0] in1;
  output reg [6:0] out1;

  always @ (in1)
    case (in1)
      4'b0000 : out1=7'b1000000; //0
      4'b0001 : out1=7'b1111001; //1
      4'b0010 : out1=7'b0100100; //2
      4'b0011 : out1=7'b0110000; //3
      4'b0100 : out1=7'b0011001; //4
      4'b0101 : out1=7'b0010010; //5
      4'b0110 : out1=7'b0000010; //6
      4'b0111 : out1=7'b1111000; //7
      4'b1000 : out1=7'b0000000; //8
      4'b1001 : out1=7'b0010000; //9
      4'b1010 : out1=7'b0001000; //A
      4'b1011 : out1=7'b0000011; //B
      4'b1100 : out1=7'b1000110; //C
      4'b1101 : out1=7'b0100001; //D
      4'b1110 : out1=7'b0000110; //E
      4'b1111 : out1=7'b0001110; //F
    endcase
      
endmodule
