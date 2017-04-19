/*
RGB_controller.sv
Contains the line-buffer based sprite controller, accessing various sprites and assigning priorities to them*/

module RGB_controller(clk,clk50,screen,
							x, y, x1,y1, x2,y2, x3,y3, x4,y4, x5,y5,
							hcount,vcount, nin_life,level,result,
							addr, addr_bg, addr_b1, addr_b2, addr_b3, addr_b4, addr_b5, addr_s, addr_sc, one, ten, hun,
							addr_nl, addr_t, /*addr_sun, addr_mn, addr_rn, addr_try, addr_sym*/, addr_sym, addr_nun, addr_b6, M_bg1, M_bg2, M_bg3, M_bg4,
							M_n1,M_n2,M_n3, M_nl1, M_nl2, M_nl3, M_sun, M_mn, M_rn, M_try, M_nun, M_sym, M_b6,
							M_b1,M_b2,M_b3,M_b4,M_b5, M_s1,M_s2,M_s3, M_ps, M_fl, M_dp,
                            M_sc0, M_sc1, M_sc2, M_sc3, M_sc4, M_sc5, M_sc6, M_sc7, M_sc8, M_sc9,
							//line_buffer,
							VGA_R, VGA_G, VGA_B
							 );

 input wire [3:0] one;  //ones place of score
 input wire [3:0] ten;  //tens place of score
 input wire [3:0] hun;  //hundreds place of score
 input wire [3:0] nin_life; //remaining ninja lives
 input wire [2:0] screen;   //Which screen?
 input wire [2:0] level;    //Which level?
 inout wire result; //pass or fail result
 input  wire [10:0] hcount; //Horizontal count
 input wire [9:0]  vcount;  //Vertical count
 input wire clk,clk50;  //Main VGA clock
 input wire [11:0] M_n1; // ROM data for  3 ninja sword positions
 input wire [11:0] M_n2;
 input wire [11:0] M_n3;
 input wire [11:0] M_b1;    // ROM data for 6 moving sprites
 input wire [11:0] M_b2;
 input wire [11:0] M_b3;
 input wire [11:0] M_b4;
 input wire [11:0] M_b5;
 input wire [11:0] M_b6;
 input wire [11:0] M_bg1;   //ROM data for 4 background splits sprites
 input wire [11:0] M_bg2;
 input wire [11:0] M_bg3;
 input wire [11:0] M_bg4;
 input wire [11:0] M_s1;    //ROM data for 3 levels sprites
 input wire [11:0] M_s2;
 input wire [11:0] M_s3;
 input wire [11:0] M_ps;    //ROM data for pass sprite
 input wire [11:0] M_fl;    //ROM data for fail sprites
 input wire [11:0] M_dp;    //ROM data for diploma sprite
 input wire [11:0] M_sc0;   //ROM data for zero-nine sprite
 input wire [11:0] M_sc1;   
 input wire [11:0] M_sc2;
 input wire [11:0] M_sc3;
 input wire [11:0] M_sc4;
 input wire [11:0] M_sc5;
 input wire [11:0] M_sc6;
 input wire [11:0] M_sc7;
 input wire [11:0] M_sc8;
 input wire [11:0] M_sc9;
 input wire [11:0] M_nl1;   //ROM data for 3 sprite lives
 input wire [11:0] M_nl2;
 input wire [11:0] M_nl3;
 input wire [11:0] M_sun;   //ROM data for sun sprite
 input wire [11:0] M_mn;    //ROM data for moon sprite
 input wire [11:0] M_rn;    //ROM data for rain sprite  
 input wire [11:0] M_nun;   //ROM data for NUNY name sprite
 input wire [11:0] M_try;   //ROM data for try again sprite
 input wire [11:0] M_sym;   //ROM data for NUNY symbol sprite
 input wire [15:0] x,y,x1,y1,x2,y2,x3,y3,x4,y4,x5,y5;   //X,Y coordinates read from SW for moving sprites
 
 output wire [11:0] addr;  //ROM address of ninja 
 output wire [11:0] addr_b1;    //ROM address of 6 moving sprites
 output wire [11:0] addr_b2;
 output wire [11:0] addr_b3;
 output wire [11:0] addr_b4;
 output wire [11:0] addr_b5;
 output wire [11:0] addr_b6;
 output wire [11:0] addr_s; //ROM address of levels sprites
 output wire [11:0] addr_sc;    //ROM address for score numbers sprites
 output wire [11:0] addr_nl;    //ROM address for ninja lives 
 output wire [14:0] addr_bg;    //ROM address for background 
 output wire [14:0] addr_nun;   //ROM address for NUNY name
 output wire [11:0] addr_sym;   //ROM address for NUNY symbol
 output wire [11:0] addr_t; //ROM address for sun/moon/rain
 output wire [7:0] VGA_R, VGA_G, VGA_B; //RGB output

//----------------MISC declarations-----------------------------

// local ROM addresses for various sprites:
 wire [11:0] addr_s1,addr_s2,addr_s3, addr_ps, addr_fl, addr_dp;
 wire [11:0] addr_nl1,addr_nl2,addr_nl3;
 wire [11:0] addr_suntemp;
 wire [11:0] addr_mntemp;
 wire [11:0] addr_rntemp;
 wire [11:0] addr_trytemp;
 wire [14:0] addr_nuntemp;
 wire [14:0] addr_symtemp;
 wire [11:0] addr_sc0, addr_sc1, addr_sc2, addr_sc3, addr_sc4, addr_sc5, addr_sc6, addr_sc7, addr_sc8, addr_sc9;

 
  reg [11:0] line_buffer [639:0];  // line buffer for sprites
  wire [10:0] xrow;	    //one row in X direction of VGA display
  logic [11:0] M_bg,addr_life;  //local backgorund sprite data
  reg [11:0] M,M_l,M_b,M_s,M_pf, M_sc, M_nl, M_temp; //local sprite ROM data

  wire [11:0] M_buf; //data to be stored in buffers
  logic [9:0] yrow; //one row in Y direction of VGA display
  
  reg [11:0] buffer1 [639:0];   //2 buffers used to store sprites
  reg [11:0] buffer2 [639:0];
  
  assign xrow = (hcount >> 1);
  assign yrow = vcount;

  reg [3:0] cnt = 4'd0;     //buffer count
  reg buf_cnt;

  reg [2:0] nin_life_temp = 3'b111;

  reg [3:0] temp, temp2, temp3; //temp registers to store ones/tens/hundreds
  reg temp_fl = 0; //temp flag to store the ones/tens/hundreds flag
  reg [10:0] tempx; //temp declarations to store the x region of ones/tens/hundreds 
  reg [10:0] tempy; //temp declarations to store the y region of ones/tens/hundreds
//-----------------------------------------------------------------------


  //--------Sprite region declarations--------------------------
  logic [10:0] regionx, regiony;    //ninja region
  logic [10:0] regionx1, regiony1;  //6 moving sprite regions
  logic [10:0] regionx2, regiony2;
  logic [10:0] regionx3, regiony3;
  logic [10:0] regionx4, regiony4;
  logic [10:0] regionx5, regiony5;
  logic [10:0] regionx6, regiony6;
  logic [10:0] stagex1, stagey1;    // 3 stages (or levels) regions
  logic [10:0] stagex2, stagey2;
  logic [10:0] stagex3, stagey3;
  logic [10:0] passx, passy;    //pass region
  logic [10:0] failx, faily;    //fail region
  logic [10:0] onex, oney;  //one's place of score region
  logic [10:0] tenx, teny;  //ten's place of score region
  logic [10:0] hunx, huny;  //hundred's place of score region
  logic [10:0] nin1x, nin1y;    //ninja life 1 region
  logic [10:0] nin2x, nin2y;    //ninja life 2 region
  logic [10:0] nin3x, nin3y;    //ninja life 2 region
  logic [10:0] sunx, suny;  //sun region
  logic [10:0] moonx, moony;    //moon region
  logic [10:0] rainx, rainy;    //rain region
  logic [10:0] tryx, tryy;  //try again region
  logic [10:0] nunx, nuny;  //nuny name sprite region
  logic [10:0] dipx, dipy;  //diploma region
  logic [10:0] symx, symy;  //NUNY symbol region
  //------------------------------------------------------------------

  //--------Assign sprite region base locations---------------------
  assign regionx=(xrow-x);
  assign regiony = (yrow-y);
  assign regionx1=(xrow-x1);
  assign regiony1 = (yrow- y1);
  assign regionx2=(xrow-x2);
  assign regiony2 = (yrow- y2);
  assign regionx3=(xrow-x3);
  assign regiony3 = (yrow- y3);
  assign regionx4=(xrow-x4);
  assign regiony4 = (yrow- y4);
  assign regionx5=(xrow-x5);
  assign regiony5 = (yrow- y5);
  assign regionx6=(xrow-x5);
  assign regiony6 = (yrow- y5);
  assign stagex1=(xrow-11'd187);
  assign stagey1 = (yrow- 10'd300);
  assign stagex2=(xrow-11'd287);
  assign stagey2 = (yrow- 10'd300);
  assign stagex3=(xrow-11'd387);
  assign stagey3 = (yrow- 10'd300);
  assign passx=(xrow-11'd187);
  assign passy = (yrow- 10'd150);
  assign failx=(xrow-11'd287);
  assign faily = (yrow- 10'd150);
  assign onex=(xrow-11'd90);
  assign oney = (yrow);
  assign tenx=(xrow-11'd50);
  assign teny = (yrow);
  assign hunx=(xrow-11'd10);
  assign huny = (yrow);
  assign nin1x=(xrow-11'd480);
  assign nin1y = (yrow);
  assign nin2x=(xrow-11'd520);
  assign nin2y = (yrow);
  assign nin3x=(xrow-11'd560);
  assign nin3y = (yrow);
  assign sunx=(xrow-11'd483);
  assign suny = (yrow-11'd50);
  assign moonx=(xrow-11'd481);
  assign moony = (yrow-11'd50);
  assign rainx=(xrow-11'd481);
  assign rainy = (yrow-11'd50);
  assign tryx=(xrow-11'd481);
  assign tryy = (yrow-11'd50);
  assign nunx=(xrow-11'd203);
  assign nuny = (yrow-11'd50);
  assign dipx=(xrow-187);
  assign dipy = (yrow-150);
  assign symx=(xrow-11'd135);
  assign symy = (yrow-11'd50);
  //-----------------------------------------------------------
  
  //-------------sprite on flags---------------------------
  logic ninja;
  logic sky;
  logic black;
  logic skyline;
  logic book;
  logic book1;
  logic book2;
  logic book3;
  logic book4;
  logic book5;
  logic book6;
  logic dip_fl;
  logic bg1,bg2,bg3,bg4;
  wire life;
  wire stage1,stage2,stage3;  
  wire pass_fl, fail_fl;
  wire one_fl, ten_fl, hun_fl;
  wire nin1_fl, nin2_fl, nin3_fl;
  wire sun_fl, moon_fl, rain_fl;
  wire nun_fl, try_fl, sym_fl;
 //----------------------------------------------------------


//-----------------Sprite flags switched ON if inside sprite region-----------------------------------
	assign sky = (yrow <= 154)?1'b1:1'b0;
	assign skyline = ((yrow>= 155 )&&(yrow <= 353))?1'b1:1'b0;
	assign black = ((yrow>= 354 ))?1'b1:1'b0;
	assign book1 = (screen[0] && regionx1[10:6]==0 && regiony1[10:6]==0)?1'b1:1'b0; 
	assign book2 = (screen[0] && regionx2[10:6]==0 && regiony2[10:6]==0)?1'b1:1'b0;
	assign book3 = (screen[0] && regionx3[10:6]==0 && regiony3[10:6]==0)?1'b1:1'b0;
	assign book4 = (screen[0] && regionx4[10:6]==0 && regiony4[10:6]==0)?1'b1:1'b0;
	assign book5 = (screen[0] && regionx5[10:6]==0 && regiony5[10:6]==0 && (level[1] == 1 || level[0] == 1))?1'b1:1'b0;
	assign book6 = (screen[0] && regionx6[10:6]==0 && regiony6[10:6]==0 && (level[2] == 1))?1'b1:1'b0;
	assign dip_fl = (screen[2] && dipx[10:6]==0 && dipy[10:6]==0 && level[2] == 1 && result == 1)?1'b1:1'b0;
	assign stage1 = (screen[1] && stagex1[10:6]==0 && stagey1[10:6]==0)?1'b1:1'b0; 
	assign stage2 = (screen[1] && stagex2[10:6]==0 && stagey2[10:6]==0)?1'b1:1'b0;
	assign stage3 = (screen[1] && stagex3[10:6]==0 && stagey3[10:6]==0)?1'b1:1'b0;
	assign nun_fl = (screen[1] && (xrow >= 205 && xrow <= 403) && (yrow >= 50 && yrow <= 95))?1'b1:1'b0;
	assign try_fl = (screen[2] && tryx[10:6]==0 && tryy[10:6]==0)?1'b1:1'b0;
	assign pass_fl = (screen[2] && passx[10:6]==0 && passy[10:6]==0 && result==1 && (level[1] == 1 || level[0] == 1))?1'b1:1'b0;
	assign fail_fl = (screen[2] && failx[10:6]==0 && faily[10:6]==0 && result==0)?1'b1:1'b0;
	assign ninja = (regionx[10:6]==0 && regiony[10:6]==0)?1'b1:1'b0; 
	assign one_fl = (onex[10:5]==0 && oney[10:5]==0)?1'b1:1'b0; 
	assign ten_fl = (tenx[10:5]==0 && teny[10:5]==0)?1'b1:1'b0; 
	assign hun_fl = (hunx[10:5]==0 && huny[10:5]==0)?1'b1:1'b0; 
	assign nin1_fl = (nin1x[10:5]==0 && nin1y[10:5]==0 && (nin_life[0] == 0))?1'b1:1'b0; 
	assign nin2_fl = (nin2x[10:5]==0 && nin2y[10:5]==0 && nin_life[1] == 0)?1'b1:1'b0; 
	assign nin3_fl = (nin3x[10:5]==0 && nin3y[10:5]==0 && nin_life[2] == 0)?1'b1:1'b0; 
	//assign sun_fl = (screen[0] && sunx[10:6]==0 && suny[10:6]==0 && level[2] == 1)?1'b1:1'b0; 
	assign sun_fl = (screen[0] && (xrow >= 483 && xrow <= 547) && (yrow >= 50 && yrow <= 114)  && level[2] == 1)?1'b1:1'b0; 
	assign sym_fl = (symx[10:6]==0 && symy[10:6]==0 && screen[1])?1'b1:1'b0; 
	assign moon_fl = (moonx[10:6]==0 && moony[10:6]==0 && level[1] == 1 && screen[0])?1'b1:1'b0; 
	assign rain_fl = (rainx[10:6]==0 && rainy[10:6]==0 && level[0] == 1 && screen[0])?1'b1:1'b0; 
	assign book = (book1 || book2 || book3 || book4 || book5 || book6);
//---------------------------------------------------------------------    


//--------Reading sprite ROM data into a local reg when sprite flag is ON--------

//sun/moon/rain/tryagain sprites
    always @(*) begin
        if (try_fl)
            M_temp = M_try;
        else if (moon_fl)
            M_temp = M_mn;
        else if (sun_fl)
            M_temp = M_sun;
        else if (rain_fl)
            M_temp = M_rn;
    end

//ninja lives
    always @(*) begin
        if (nin1_fl)
            M_nl = M_nl1;
        else if (nin2_fl)
            M_nl = M_nl2;
        else if (nin3_fl)
            M_nl = M_nl3;
    end

//number ones/tens/hundreds sprites 
    always @(*) begin
        if (one_fl)
            temp = one;
        else if (ten_fl)
            temp = ten;
        else if (hun_fl)
            temp = hun;
        else
            temp = one;
        case (temp)
            4'd0: M_sc = M_sc0;
            4'd1: M_sc = M_sc1;
            4'd2: M_sc = M_sc2;
            4'd3: M_sc = M_sc3;
            4'd4: M_sc = M_sc4;
            4'd5: M_sc = M_sc5;
            4'd6: M_sc = M_sc6;
            4'd7: M_sc = M_sc7;
            4'd8: M_sc = M_sc8;
            4'd9: M_sc = M_sc9;
            default: M_sc = M_sc0;
        endcase
    end

		// selecting background sprites
	always @(*)
		begin
			if (skyline==1) begin			
			//background sprite 5
				if ((xrow>= 0 )&& (xrow <= 159)) begin
				  M_bg = M_bg1;
			   end
		  //backgroung sprite 3
		  else if ((xrow>= 160 )&& (xrow <= 320)) begin
			   M_bg = M_bg2;
				end
		 if ((xrow>= 321 )&& (xrow <= 480)) begin
				  M_bg = M_bg3;
			   end
		  //backgroung sprite 4
		  else if ((xrow>= 481 )&& (xrow <= 639)) begin
			   M_bg = M_bg4;
				end 
				end
				//M_bg = 12'd0;
		end
	
	//selection of moving sprites
	always @(*) begin
		if ((book1==1) && M_b1!=12'd4095) begin
			M_b = M_b1;
		end
		else if ((book2==1) && M_b2!=12'd4095) begin
			M_b = M_b2;
		end
		else if ((book3==1) && M_b3!=12'd4095) begin
			M_b = M_b3;
		end
		else if ((book4==1) && M_b4!=12'd3567) begin
			M_b = M_b4;
		end
		else if ((book5==1) && M_b5!=12'd0000) begin
			M_b = M_b5;
        end
		else if ((book6==1) && M_b6!=12'd0000) begin
			M_b = M_b6;
		end else
			M_b = 12'd4095;
		end
		
	//selecting stage selection/pass/fail/diploma sprites
	always @(*) begin
		if ((stage1==1)) begin
			M_s = M_s1;
		end
		else if ((stage2==1)) begin
			M_s = M_s2;
		end
		else if ((stage3==1)) begin
			M_s = M_s3;
		end
		else if ((pass_fl==1)) begin
			M_s = M_ps;
		end
		else if ((fail_fl==1)) begin
			M_s = M_fl;
			end
		else if ((dip_fl==1)) begin
			M_s = M_dp;
		end
		end
	

	// ninja sprite selection of sword position
	always_ff @(posedge clk)
	begin		 
	 case(cnt)
	4'd0:	M <= M_n1;
	4'd1:	M <= M_n1;
	4'd2:	M <= M_n1;
	4'd3:	M <= M_n1;
	4'd4:	M <= M_n2;
	4'd5:	M <= M_n2;
	4'd6:	M <= M_n2;
	4'd7:	M <= M_n2;
	4'd8:	M <= M_n3;
	4'd9:	M <= M_n3;
	4'd10:	M <= M_n3;
	4'd11:	M <= M_n3;
	4'd12:	M <= M_n2;
	4'd13:	M <= M_n2;
	4'd14:	M <= M_n2;
	4'd15:	M <= M_n2;
	endcase
	end
//--------------------------------------------------------

//--------Reading sprite ROM address into a local reg when sprite flag is ON-------

	// address of sprite rom blocks 
	assign addr = (ninja)? (regiony*64+regionx):12'd0;  //ninja
	assign addr_b1 = (book1)? (regiony1*64+regionx1):12'd0; // 6 moving sprites
	assign addr_b2 = (book2)? (regiony2*64+regionx2):12'd0;
	assign addr_b3 = (book3)? (regiony3*64+regionx3):12'd0;
	assign addr_b4 = (book4)? (regiony4*64+regionx4):12'd0;
	assign addr_b5 = (book5)? (regiony5*64+regionx5):12'd0;
	assign addr_b6 = (book6)? (regiony6*64+regionx6):12'd0;

	assign addr_dp = (dip_fl)? (dipy*64+dipx):12'd0;    //diploma sprite

	assign addr_s1 = (stage1)? (stagey1*64+stagex1):12'd0; //3 stages
	assign addr_s2 = (stage2)? (stagey2*64+stagex2):12'd0;
	assign addr_s3 = (stage3)? (stagey3*64+stagex3):12'd0;

	assign addr_ps = (pass_fl)? (passy*64+passx):12'd0; //pass/fail
	assign addr_fl = (fail_fl)? (faily*64+failx):12'd0;

	assign addr_t = (try_fl || sun_fl || moon_fl || rain_fl)? (tryy*64+tryx):12'd0; //sun/moon/rain/tryagain

	assign addr_sym = (sym_fl)? (symy*64+symx):12'd0; //symbol
	assign addr_nun = (nun_fl)? (nuny*400+nunx%400):12'd0; //nuny name

	assign addr_nl1 = (nin1_fl)? (nin1y*32+nin1x):12'd0; //3 ninja lives
	assign addr_nl2 = (nin2_fl)? (nin2y*32+nin2x):12'd0;
	assign addr_nl3 = (nin3_fl)? (nin3y*32+nin3x):12'd0;

	assign addr_bg = (skyline)? ((yrow-155)*160+xrow%160):15'd0; //background sprite

//which of the three ninja lives address
    always @(*) begin
        if (nin1_fl)
            addr_nl = addr_nl1;
        else if (nin2_fl)
            addr_nl = addr_nl2;
        else if (nin3_fl)
            addr_nl = addr_nl3;
        else
            addr_nl = 12'd0;
    end

    // assign number ROM addresses based on the number in ones/tens/hundreds place
    always_comb begin
        if (one_fl) begin
            temp3 = one;
            temp_fl = 1;
            tempx = onex;
            tempy = oney;
        end
        else if (ten_fl) begin
            temp3 = ten;
            temp_fl = 1;
            tempx = tenx;
            tempy = teny;
        end
        else if (hun_fl) begin
            temp3 = hun;
            temp_fl = 1;
            tempx = hunx; 
            tempy = huny;
        end
        else begin
            temp_fl = 0;
            temp3 = 0;
            tempx = onex;
            tempy = oney;
        end
            
        addr_sc0 = (temp_fl == 1 && temp3 == 0)?(tempy*32+tempx):12'd0;
        addr_sc1 = (temp_fl == 1 && temp3 == 1)?(tempy*32+tempx):12'd0;
        addr_sc2 = (temp_fl == 1 && temp3 == 2)?(tempy*32+tempx):12'd0;
        addr_sc3 = (temp_fl == 1 && temp3 == 3)?(tempy*32+tempx):12'd0;
        addr_sc4 = (temp_fl == 1 && temp3 == 4)?(tempy*32+tempx):12'd0;
        addr_sc5 = (temp_fl == 1 && temp3 == 5)?(tempy*32+tempx):12'd0;
        addr_sc6 = (temp_fl == 1 && temp3 == 6)?(tempy*32+tempx):12'd0;
        addr_sc7 = (temp_fl == 1 && temp3 == 7)?(tempy*32+tempx):12'd0;
        addr_sc8 = (temp_fl == 1 && temp3 == 8)?(tempy*32+tempx):12'd0;
        addr_sc9 = (temp_fl == 1 && temp3 == 9)?(tempy*32+tempx):12'd0;
        
    end

//Since only one address used for all the numbers ROM blocks, select which address based on
// the number in the ones/tens/hundreds place 
    always @(*) begin
        if (one_fl)
            temp2 = one;
        else if (ten_fl)
            temp2 = ten;
        else if (hun_fl)
            temp2 = hun;
        else
            temp2 = one;
            
        case (temp2)
            4'd0: addr_sc = addr_sc0;
            4'd1: addr_sc = addr_sc1;
            4'd2: addr_sc = addr_sc2;
            4'd3: addr_sc = addr_sc3;
            4'd4: addr_sc = addr_sc4;
            4'd5: addr_sc = addr_sc5;
            4'd6: addr_sc = addr_sc6;
            4'd7: addr_sc = addr_sc7;
            4'd8: addr_sc = addr_sc8;
            4'd9: addr_sc = addr_sc9;
            default: addr_sc = addr_sc0;
        endcase
    end
  
// stage/pass/fail/diploma sprites have same address, selecting here based on flag 
	always @(*) begin
		if (stage1 )
			addr_s = addr_s1;
		else if (stage2 )
			addr_s = addr_s2;
		else if (stage3 )
			addr_s = addr_s3;
        else if (pass_fl)
            addr_s = addr_ps;
        else if (fail_fl)
            addr_s = addr_fl;
        else if (dip_fl)
            addr_s = addr_dp;
		else addr_s = 12'd0;
	end	
//------------------------------------------------------------------------------------	

//-----------Writing sprite data to buffers at clock edge----------------------------
	
  // counter for moving ninja sword on position
	always@(vcount)
	if (vcount == 520) begin
	cnt <= cnt + 1;
	end
	else begin
	cnt <= cnt;
	end
	
	//counter for writing into the buffers
	always@(posedge vcount[0])
	buf_cnt <= buf_cnt + 1;
	
	// writing into the buffers
	always @(posedge clk) begin
	 	if (buf_cnt==0)
				buffer1[xrow] <= M_buf;
		else 
				buffer2[xrow] <= M_buf;
	end

	always @(posedge clk) begin
	 	if (buf_cnt==0)
				line_buffer[xrow] <= buffer2[xrow];
		else 
				line_buffer[xrow] <= buffer1[xrow];
	end


    //----------------------Sprite priority encoder---------------------
   always_comb begin
        M_buf = 12'h0fe;    // write white to pixel bt default		

		if (ninja==1 && M!=12'd4095) begin
		    M_buf = M;
		end	
		else if ((book==1)  && M_b!=12'd4095) begin
			M_buf = M_b;
		end	
		else if (((nin1_fl) || (nin2_fl) || (nin3_fl)) && M_nl!=12'd4095) begin
			M_buf = M_nl;
		end
		else if ((one_fl || ten_fl || hun_fl) && M_sc!=12'd4095) begin
		    M_buf = M_sc;
		end	
		else if ((sun_fl || moon_fl || try_fl || rain_fl ) && (M_temp != 12'd4095 && M_temp != 12'd0)) begin
		    M_buf = M_temp;
		end	
		else if ((nun_fl) && M_nun!=12'd4095) begin
		    M_buf = M_nun;
		end	
		else if ((sym_fl) && M_sym!=12'd4095) begin
		    M_buf = M_sym;
		end	
		else if ((stage1 || stage2 || stage3 ||pass_fl ||fail_fl || dip_fl)&& M_s!=12'd4095) begin
			M_buf = M_s;
		end
	   else if ((skyline==1) && (M_bg!=12'd4095)) begin
			M_buf = M_bg;
			end
		else if (sky==1) begin
		M_buf = 12'h0fe;
		end
		
		else if (black==1) begin
	    	M_buf = 12'h000;
			end
	  end 
//---------------------------------------------------------------------------------- 
  
//-----------------------Writing RGB values---------------------------------- 
assign VGA_R = {line_buffer[xrow][11:8],line_buffer[xrow][11:8]}; 
assign VGA_G = {line_buffer[xrow][7:4],line_buffer[xrow][7:4]};
assign VGA_B = {line_buffer[xrow][3:0],line_buffer[xrow][3:0]};

endmodule 
 



