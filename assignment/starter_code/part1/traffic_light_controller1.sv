// traffic light controller
// CSE140L 3-street, 12-state version
// inserts all-red after each yellow
// uses enumerated variables for states and for red-yellow-green
// 5 after traffic, 10 max cycles for green after conflict
// starter (shell) -- you need to complete the always_comb logic
import light_package ::*;           // defines red, yellow, green

// same as Harris & Harris 4-state, but we have added two all-reds
module traffic_light_controller1(
  input         clk, reset, 
                ew_str_sensor, ew_left_sensor, ns_sensor,  // traffic sensors, east-west straight, east-west left, north-south 
  output colors ew_str_light, ew_left_light, ns_light);    // traffic lights, east-west straight, east-west left, north-south

// HRR = red-red following YRR; RRH = red-red following RRY;
// ZRR = 2nd cycle yellow, follows YRR, etc. 
  typedef enum logic[3:0] {GRR, YRR, ZRR, HRR, RGR, RYR, RZR, RHR, RRG, RRY, RRZ, RRH} tlc_states;  
  tlc_states    present_state, next_state;
  integer ctr5, next_ctr5,       //  5 sec timeout when my traffic goes away
          ctr10, next_ctr10;     // 10 sec limit when other traffic presents

// sequential part of our state machine (register between C1 and C2 in Harris & Harris Moore machine diagram
// combinational part will reset or increment the counters and figure out the next_state
  always_ff @(posedge clk)
    if(reset) begin
	  present_state <= RRH;
      ctr5          <= 0;
      ctr10         <= 0;
    end  
	else begin
	  present_state <= next_state;
      ctr5          <= next_ctr5;
      ctr10         <= next_ctr10;
    end
	 

// combinational part of state machine ("C1" block in the Harris & Harris Moore machine diagram)
// default needed because only 6 of 8 possible states are defined/used
  always_comb begin
    next_state = RRH;            // default to reset state
    next_ctr5  = 0; 	         // default to clearing counters
    next_ctr10 = 0;
	case(present_state)
			
	GRR: 
			if (ctr5 >= 4 || ctr10 >= 9)					next_state = YRR;
	
			else if(((ctr5 > 0 || ctr10 > 0) || !ew_str_sensor) || (ns_sensor || ew_left_sensor)) begin 
			
				if( ctr5 > 0 || !ew_str_sensor) next_ctr5 = ctr5 + 1;
				else;
				
				if (ctr10 > 0 || (ns_sensor || ew_left_sensor))	next_ctr10 = ctr10 + 1;
				else;
					next_state = GRR;
																	
			end
			
			elsenext_state = GRR;
		
	YRR:  begin
          next_state = ZRR; 
          next_ctr5 = 0;
          next_ctr10 = 0;
			end
	ZRR: next_state = HRR;
	
	HRR:	if(ew_left_sensor)   	next_state = RGR;
			else if(ns_sensor)   	next_state = RRG;
			else if(ew_str_sensor)	next_state = GRR;
			else							next_state = HRR;
	
	RGR:  
			if (ctr5 >= 4 || ctr10 >= 9)next_state = RYR;
	
			else if(((ctr5 > 0 || ctr10 > 0) || !ew_left_sensor) || (ns_sensor || ew_str_sensor)) begin 
			
				if( ctr5 > 0 || !ew_left_sensor)next_ctr5 = ctr5 + 1;
				else;
				
				if (ctr10 > 0 || (ns_sensor || ew_str_sensor))	next_ctr10 = ctr10 + 1;
				else;
					next_state = RGR;
																	
			end
			
			else next_state = RGR;
	
	RYR:  begin
          next_state = RZR;
          next_ctr5 = 0;
          next_ctr10 = 0;
			end
	RZR: next_state = RHR;
	
	RHR:	if(ns_sensor)				next_state = RRG;
			else if(ew_str_sensor)	next_state = GRR;
			else if(ew_left_sensor)	next_state = RGR;
			else	next_state = RHR;
	
	RRG:	
			if (ctr5 >= 4 || ctr10 >= 9)	next_state = RRY;
	
			else if(((ctr5 > 0 || ctr10 > 0) || !ns_sensor) || (ew_left_sensor || ew_str_sensor)) begin 
			
				if( ctr5 > 0 || !ns_sensor)	next_ctr5 = ctr5 + 1;
				else;
				
				if (ctr10 > 0 || (ew_left_sensor || ew_str_sensor))	next_ctr10 = ctr10 + 1;
				else;
					next_state = RRG;
																	
			end
			
			else	next_state = RRG;
	
	RRY:	begin
          next_state = RRZ; 
          next_ctr5 = 0;
          next_ctr10 = 0;
			end
	
	RRZ: next_state = RRH;
	
	RRH:	if(ew_str_sensor)			next_state = GRR;
			else if(ew_left_sensor)	next_state = RGR;
			else if(ns_sensor)		next_state = RRG;
			else							next_state = RRH;
			
	endcase
         // what does ctr5 do? ctr10?

	 
  end

// combination output driver  ("C2" block in the Harris & Harris Moore machine diagram)
  always_comb begin
    ew_str_light  = red;                // cover all red plus undefined cases
	ew_left_light = red;
	ns_light      = red;
    case(present_state)      // Moore machine
      GRR:     ew_str_light  = green;
	  YRR,ZRR: ew_str_light  = yellow;  // my dual yellow states -- brute force way to make yellow last 2 cycles
	  RGR:     ew_left_light = green;
	  RYR,RZR: ew_left_light = yellow;
	  RRG:     ns_light      = green;
	  RRY,RRZ: ns_light      = yellow;
    endcase
  end

endmodule