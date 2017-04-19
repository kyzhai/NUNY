
/* VGA_LED.sv 
top-level module for VGA display, contains instantiations for sprite ROM blocks
and also communicates with the avalon bus*/

module VGA_LED(
			 //read from avalon bus
		   input logic clk,
	       input logic 	  reset,
	       input logic [15:0]  writedata,
	       input logic 	  write,
	       input 		  chipselect,
			 input logic [3:0] address,
			 // output to VGA
	       output logic [7:0] VGA_R, VGA_G, VGA_B,
	       output logic 	  VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n,
	       output logic 	  VGA_SYNC_n);


	//-------- coordinates of the sprites read from software------------ 
    logic [15:0] x,y;//ninja coordinates
	logic [15:0] x1,y1;//book1 coordinates
	logic [15:0] x2,y2;//book2 coordinates
	logic [15:0] x3,y3;//book3 coordinates
	logic [15:0] x4,y4;//book4 coordinates
	logic [15:0] x5,y5;//bomb coordinates
    //------------------------------------------------------------------
	
	//-----------address of sprite block roms---------------------
	wire [11:0] addr; 	    // ninja address
	wire [11:0] addr_b1;	// book1 address
	wire [11:0] addr_b2;	// book2 address
	wire [11:0] addr_b3;	// book3 address
	wire [11:0] addr_b4;	// book4 address
	wire [11:0] addr_b5;	// bomb address
	wire [11:0] addr_b6;	// bomb address
	wire [11:0] addr_s;	    // stage address
	wire [11:0] addr_ps;	// pass address
	wire [11:0] addr_fl;	// fail address
	wire [14:0] addr_bg;	// background address
	wire [11:0] addr_sc;	// score address
    wire [11:0] addr_nl;    // life address
    wire [14:0] addr_nun;   //Ninja University name address
    wire [14:0] addr_sym;   //NUNY symbol address
    wire [14:0] addr_t;     //Address for sun/moon/rain sprites, used for different levels
    //-----------------------------------------------------------------
	
	//-------------- sprite block rom data (12 bits)------------
	wire [11:0] M_bg1;  //Data for background split sprite 1
	wire [11:0] M_bg2;  //Data for background split sprite 2
	wire [11:0] M_bg3;  //Data for background split sprite 3
	wire [11:0] M_bg4;  //Data for background split sprite 4
	wire [11:0] M_n1;   //Data for ninja (sword position 1)
	wire [11:0] M_n2;   //Data for ninja (sword position 2)
	wire [11:0] M_n3;   //Data for ninja (sword position 3)
	wire [11:0] M_b1;   //Data for book1 sprite object
	wire [11:0] M_b2;   //Data for book2 sprite object
	wire [11:0] M_b3;   //Data for book3 sprite object
	wire [11:0] M_b4;   //Data for book4 sprite object
	wire [11:0] M_b5;   //Data for book5 sprite object
	wire [11:0] M_b6;   //Data for book6 sprite object
	wire [11:0] M_s1;   //Data for stage1 sprite
	wire [11:0] M_s2;   //Data for stage2 sprite
	wire [11:0] M_s3;   //Data for stage3 sprite
	wire [11:0] M_ps;   //Data for pass sprite
	wire [11:0] M_dp;   //Data for diploma sprite
	wire [11:0] M_fl;   //Data for fail sprite
    wire [11:0] M_sc0;  //Data for number 0 in score
    wire [11:0] M_sc1;  //Data for number 1 in score
    wire [11:0] M_sc2;  //Data for number 2 in score
    wire [11:0] M_sc3;  //Data for number 3 in score
    wire [11:0] M_sc4;  //Data for number 4 in score
    wire [11:0] M_sc5;  //Data for number 5 in score
    wire [11:0] M_sc6;  //Data for number 6 in score
    wire [11:0] M_sc7;  //Data for number 7 in score
    wire [11:0] M_sc8;  //Data for number 8 in score
    wire [11:0] M_sc9;  //Data for number 9 in score

    wire [11:0] M_nl1;  //Data for ninja life 1
    wire [11:0] M_nl2;  //Data for ninja life 2
    wire [11:0] M_nl3;  //Data for ninja life 3

    wire[11:0] M_sun;   //Data for sun sprite for level 1
    wire[11:0] M_mn;    //Data for moon sprite for level 2
    wire[11:0] M_rn;    //Data for rain sprite for level 3
	
    wire[11:0] M_try;   //Try again sprite used in last screen

    wire[11:0] M_nun;   //Data for NUNY name sprite on selection screen
    wire[11:0] M_sym;   //Data for NUNY symbol sprite
    //--------------------------------------------------------------

    //-------------------Misc declarations-------------------------

    wire [10:0] hcount; //hcount for VGA
	wire [9:0] vcount;  //vcount for VGA
	wire [10:0] xrow;   //Reading the horizontal axis of display 
	wire [1:0] state;   //state read from SW to decide which screen
	wire [2:0] screen;  //which screen (1-hot code)
	wire [2:0] level;   //which level BA, MS, Phd (1-hot code)
	wire result;    //result pass or fail

    wire [7:0] score; //What is the score read from SW
    wire [3:0] one; //One's place of score
    wire [3:0] ten; //Ten's place of score
    wire [3:0] hun; //Hundred's place of score

    reg [2:0] nin_life = 3'b000; //How many ninja lives to display
    //-------------------------------------------------------------

    //-------------Call VGA controller--------------------------	
	VGA_LED_Emulator led_emulator(.clk50(clk), 
											.reset(reset),
											.hcount(hcount),
											.vcount(vcount),
											.VGA_CLK (VGA_CLK),
											.VGA_HS (VGA_HS),
											.VGA_VS (VGA_VS),
											.VGA_BLANK_n (VGA_BLANK_n),
											.VGA_SYNC_n (VGA_SYNC_n));
    //---------------------------------------------------------------
											
	//--------------block rom for sprites---------------------------
	ninja1 ninja1(.clock(VGA_CLK), .address(addr), .q(M_n1));   //ninja sword position 1
	ninja2 ninja2(.clock(VGA_CLK), .address(addr), .q(M_n2));   //ninja sword position 2
	ninja3 ninja3(.clock(VGA_CLK), .address(addr), .q(M_n3));   //ninja sword position 3
	
	reading book1(.clock(VGA_CLK), .address(addr_b1), .q(M_b1));    //reading sprite
	exam book2(.clock(VGA_CLK), .address(addr_b2), .q(M_b2));       //exam sprite
	homework book3(.clock(VGA_CLK), .address(addr_b3), .q(M_b3));   //homework sprite
	bomb book4(.clock(VGA_CLK), .address(addr_b4), .q(M_b4));   //Bomb sprite
	pizza book5(.clock(VGA_CLK), .address(addr_b5), .q(M_b5));  //Pizza sprite
	thesis_new book6(.clock(VGA_CLK), .address(addr_b6), .q(M_b6)); //Thesis sprite
	
	bg1_new  prom_bg1(.clock(VGA_CLK), .address(addr_bg), .q(M_bg1));   //Background split 1 sprite
	bg2_new  prom_bg2(.clock(VGA_CLK), .address(addr_bg), .q(M_bg2));   //Background split 2 sprite
	bg3_new  prom_bg3(.clock(VGA_CLK), .address(addr_bg), .q(M_bg3));   //Background split 3 sprite
	bg4_new  prom_bg4(.clock(VGA_CLK), .address(addr_bg), .q(M_bg4));   //Background split 4 sprite
	
	bach_new level1(.clock(VGA_CLK), .address(addr_s), .q(M_s1));   //BA level sprite
	mast_new level2(.clock(VGA_CLK), .address(addr_s), .q(M_s2));   //MA level sprite
	phd_new	level3(.clock(VGA_CLK), .address(addr_s), .q(M_s3));    //PhD level sprite
	
    pass_new ps(.clock(VGA_CLK), .address(addr_s), .q(M_ps));   //pass sprite
    fail_new fl(.clock(VGA_CLK), .address(addr_s), .q(M_fl));   //fail sprite
	diploma_new dip0(.clock(VGA_CLK), .address(addr_s), .q(M_dp));  //diploma sprite

    zero_new2 sc0(.clock(VGA_CLK), .address(addr_sc), .q(M_sc0));   //Zero number sprite
    one_new2 sc1(.clock(VGA_CLK), .address(addr_sc), .q(M_sc1));    //One number sprite
    two_new2 sc2(.clock(VGA_CLK), .address(addr_sc), .q(M_sc2));    //Two number sprite
    three_new2 sc3(.clock(VGA_CLK), .address(addr_sc), .q(M_sc3));  //Three number sprite
    four_new2 sc4(.clock(VGA_CLK), .address(addr_sc), .q(M_sc4));   //Four number sprite
    five_new2 sc5(.clock(VGA_CLK), .address(addr_sc), .q(M_sc5));   //Five number sprite
    six_new2 sc6(.clock(VGA_CLK), .address(addr_sc), .q(M_sc6));    //Six number sprite
    seven_new2 sc7(.clock(VGA_CLK), .address(addr_sc), .q(M_sc7));  //Seven number sprite
    eight_new2 sc8(.clock(VGA_CLK), .address(addr_sc), .q(M_sc8));  //Eight number sprite
    nine_new2 sc9(.clock(VGA_CLK), .address(addr_sc), .q(M_sc9));   //Nine number sprite
	
	life_new nl1(.clock(VGA_CLK), .address(addr_nl), .q(M_nl1));    //Life sprite instantiated 3 times
	life_new nl2(.clock(VGA_CLK), .address(addr_nl), .q(M_nl2));
	life_new nl3(.clock(VGA_CLK), .address(addr_nl), .q(M_nl3));
    
	sun sun0(.clock(VGA_CLK), .address(addr_t), .q(M_sun)); // Sun sprite in BA level
	moon mn0(.clock(VGA_CLK), .address(addr_t), .q(M_mn));  //Moon sprite in MA level
	rain rn0(.clock(VGA_CLK), .address(addr_t), .q(M_rn));  //Rain sprite in PhD level
    
	nuny_new2 nun0(.clock(VGA_CLK), .address(addr_nun), .q(M_nun)); //NUNY name sprite used in selection sprite
	ninjasymbol sym0(.clock(VGA_CLK), .address(addr_sym), .q(M_sym));   //Ninja symbol sprite
    
	tryagain try0(.clock(VGA_CLK), .address(addr_t), .q(M_try));    //Try again sprite
    //--------------------------------------------------------------------
    
    //----------Call the sprite controller module-----------------------------------
	RGB_controller controller_1(.clk(VGA_CLK),
										.clk50(clk),
										.hcount(hcount),
										.vcount(vcount),
										.x(x), .y(y),
										.x1(x1), .y1(y1),
										.x2(x2), .y2(y2),
										.x3(x3), .y3(y3),
										.x4(x4), .y4(y4),
										.x5(x5), .y5(y5),
                                        .one(one),
                                        .ten(ten),
                                        .hun(hun),
										.addr(addr),
										.addr_b1(addr_b1),
										.addr_b2(addr_b2),
										.addr_b3(addr_b3),
										.addr_b4(addr_b4),
										.addr_b5(addr_b5),
										.addr_b6(addr_b6),
										.addr_s(addr_s),
										.addr_sc(addr_sc),
										.addr_nl(addr_nl),
										.addr_t(addr_t),
										//.addr_sun(addr_sun),
										//.addr_mn(addr_mn),
										//.addr_rn(addr_rn),
										//.addr_try(addr_try),
										.addr_nun(addr_nun),
										.addr_sym(addr_sym),
										.M_s1(M_s1),
										.M_s2(M_s2),
										.M_s3(M_s3),
										.M_n1(M_n1),
										.M_n2(M_n2),
										.M_n3(M_n3),
										.M_b1(M_b1),
										.M_b2(M_b2),
										.M_b3(M_b3),
										.M_b4(M_b4),
										.M_b5(M_b5),
										.M_b6(M_b6),
										.M_ps(M_ps),
										.M_dp(M_dp),
										.M_fl(M_fl),
                                        .M_sc0(M_sc0),
                                        .M_sc1(M_sc1),
                                        .M_sc2(M_sc2),
                                        .M_sc3(M_sc3),
                                        .M_sc4(M_sc4),
                                        .M_sc5(M_sc5),
                                        .M_sc6(M_sc6),
                                        .M_sc7(M_sc7),
                                        .M_sc8(M_sc8),
                                        .M_sc9(M_sc9),
                                        .M_nl1(M_nl1),
                                        .M_nl2(M_nl2),
                                        .M_nl3(M_nl3),
                                        .M_sun(M_sun),
                                        .M_mn(M_mn),
                                        .M_rn(M_rn),
                                        .M_try(M_try),
                                        .M_nun(M_nun),
                                        .M_sym(M_sym),
										.addr_bg(addr_bg), 
										.M_bg1(M_bg1),
										.M_bg2(M_bg2),
										.M_bg3(M_bg3),
										.M_bg4(M_bg4),
										.screen(screen),
                                        .level(level),
                                        .result(result),
										.nin_life(nin_life),
										//.line_buffer(line_buffer)
										.VGA_R(VGA_R),
					.VGA_G(VGA_G),
					.VGA_B(VGA_B)
										);
//---------------------------------------------------------------------------


   //---------------Read from the VGA peripheral memory from various addresses--------	
   always_ff @(posedge clk)
     if (reset) begin
	x <= 16'd300; 
	y <= 16'd200;
	x1 <= 16'd10;
	y1 <= 16'd300;
	x2 <= 16'd70;
	y2 <= 16'd300;
	x3 <= 16'd200;
	y3 <= 16'd300;
	x4 <= 16'd300;
	y4 <= 16'd300;
	x5 <= 16'd500;
	y5 <= 16'd300;
	state <= 2'b00;
	score <= 8'b0;
	nin_life <= 3'b0;
	level <= 3'b0;
	result <= 1'b0;

	end
	else if (chipselect && write)
	begin
		 
	case(address)
	4'b0000: x <= writedata;    //Get coordinates of ninja and other moving sprites 
	4'b0001: y <= writedata;
	4'b0010: x1 <= writedata; 
	4'b0011: y1 <= writedata;
	4'b0100: x2 <= writedata; 
	4'b0101: y2 <= writedata;
	4'b0110: x3 <= writedata; 
	4'b0111: y3 <= writedata;
	4'b1000: x4 <= writedata; 
	4'b1001: y4 <= writedata;
	4'b1010: x5 <= writedata; 
	4'b1011: y5 <= writedata;
	4'b1100:begin           //get screen, level, pass/fail info
            state <= writedata[1:0];
            level <= writedata[4:2];
            result <= writedata[5];
				end
	4'b1101: score <= writedata[7:0];   //get score
	4'b1110: nin_life <= writedata[2:0];    //get lives remaining
	4'b1111: state<= 2'b0;  //default
	endcase
	end
//----------------------------------------------------------------------------------

//-------------Select screen based on the state read from SW-----------------------
	always_ff @(posedge clk) begin
	if (reset)
		screen = 3'b010;
	else case(state)
		2'b00: screen <= 3'b010;
		2'b01: screen <= 3'b001;
		2'b10: screen <= 3'b100;
		default: screen <=3'b010;
		endcase
	end
//---------------------------------------------------------------------------------


    //--------------Decimal to BCD converter to convert score into ones/tens/hundreds--------
    integer i;
    always @(score) begin
        hun = 4'd0;
        ten = 4'd0;
        one = 4'd0;

        for (i = 7; i >= 0; i = i -1) begin
            if (hun >= 5)
                hun = hun + 3;
            if (ten >= 5)
                ten = ten + 3;
            if (one >= 5)
                one = one + 3;

            hun = hun << 1;
            hun[0] = ten[3];
            ten = ten << 1;
            ten[0] = one[3];
            one = one << 1;
            one[0] = score[i];
        end
    end
	//--------------------------------------------------------------------------------------
endmodule
