drop table combos;
create table combos (id number,board varchar2(36));

DECLARE
	TYPE BlockType IS RECORD (
		x NUMBER(1),
		y NUMBER(1),
		length number(1),
		orientation varchar2(1),
		marker varchar2(1)
	);
	type blocksArrayType IS TABLE OF BlockType INDEX BY binary_integer;
	type gridcell IS TABLE OF varchar2(1) INDEX BY binary_integer;
	type gridtype IS TABLE OF gridcell INDEX BY binary_integer;
	type stepstype IS TABLE OF blocksArrayType index by varchar2(36);
	
	blocks blocksArrayType;
	board gridtype;
	block blocktype;
	steps stepstype;
	x number;
	y number;
	cnt number := 0;
	id number := 0;



  
	function boardtostring(a_board gridtype) return varchar2 is
	v_str varchar2(36);
	begin
		for i in 0..5 loop
			for j in 0..5 loop
				v_str := v_str || a_board(i)(j);
			end loop;		
		end loop;
	return(v_str);
	end;

	
	procedure printboard (a_idx number) is
	v_str varchar2(36);
	begin
		if blocks.count = a_idx + 1 then
			cnt := cnt + 1;
			v_str := boardtostring;
			insert into combos values(id,v_str);
			id := id + 1;
		end if;
	end;
	
	procedure removeblock(a_block IN OUT blocktype) is
	begin
		for i in 0..5 loop
			for j in 0..5 loop
				if board(i)(j) = a_block.marker then
					board(i)(j) := '0';
				end if;
			end loop;		
		end loop;
	end;
	
	procedure removeblock(a_idx number) is
	begin
		if blocks.count >= a_idx + 1 then
			removeblock(blocks(a_idx));
		end if;
	end;

	
	function setblock(a_block IN OUT blocktype, a_pos number) return boolean is
	canset boolean;
	a_x number;
	a_y number;
	begin
--	  dbms_output.put_line(a_x||a_y||a_block.orientation);
		a_x := a_block.x;
		a_y := a_block.y;
		
		if a_block.orientation = '-' then
			a_x := a_pos;
			canset := a_x >= 0 and a_x <= 6 - a_block.length ;
			if not canset then 
				return (false);
			end if;
			for i in 0..a_block.length - 1 loop
				canset := canset and board(a_y)(a_x + i) in ('0',a_block.marker);
			end loop;
			if not canset then 
				return (false);
			end if;

			removeblock(a_block);
			
			for i in 0..a_block.length - 1 loop
				board(a_y)(a_x + i) := a_block.marker;
			end loop;
			
		else
			a_y := a_pos;
			canset := a_y >= 0 and a_y <= 6 - a_block.length ;
			if not canset then 
				return (false);
			end if;
			for i in 0..a_block.length - 1 loop
				canset := canset and board(a_y + i)(a_x) in ('0',a_block.marker);
			end loop;
			if not canset then 
				return (false);
			end if;
			
			removeblock(a_block);
			
			for i in 0..a_block.length - 1 loop
				board(a_y + i)(a_x) := a_block.marker;
			end loop;
			
		end if;

		a_block.x := a_x;
		a_block.y := a_y;		
		return(true);
	end;

	procedure registerblock (a_x number, a_y number, a_l number, a_O varchar2, a_m varchar2 default null) is
	id number;
	begin
		id := blocks.count;

		blocks(id).x := a_x;
		blocks(id).y := a_y;
		blocks(id).length := a_l;
		blocks(id).orientation := a_o;
		blocks(id).marker := nvl(a_m,CHR(ASCII('A') + id));
	end;
   
	procedure stringtoblocks(a_str varchar2) is
  v_processed varchar2(30) := ' ';
  v_l number;
  v_o varchar2(1);
  v_x number;
  v_y number;
  v_m varchar2(1);
  v_grid_size number := 6;
  
	begin
		for i in 1..36 loop
			v_m := substr(a_str, i , 1);
      if v_m <> '0' and instr(v_processed, v_m) = 0 then
				v_x := mod((i - 1),6);
				v_y := trunc((i - 1)/6);
				v_l := 1;

				if v_x < v_grid_size and substr(a_str, i + 1, 1) = v_m then
					v_o := '-';
					if v_x < v_grid_size - 1 and substr(a_str, i + 2, 1) = v_m then
						v_l := 3;
					else
						v_l := 2;
					end if;
				elsif v_y < v_grid_size and substr(a_str, i + 6, 1) = v_m then
					v_o := '|';
					if v_y < v_grid_size - 1 and substr(a_str, i + 12, 1) = v_m then
						v_l := 3;
					else
						v_l := 2;
					end if;				
				end if;

				v_processed := v_processed || v_m;
				registerblock(v_x,v_y,v_l,v_o,v_m);
      end if;
		end loop;
	end;   
   
	procedure init is
	v_str varchar2(36);
	begin
		for i in 0..5 loop
			for j in 0..5 loop
				board(i)(j) := '0';
			end loop;		
		end loop;

--  v_str := 'ABBB0CA0DE0CXXDE0C00DFGG0HHFJ00IIIJ0';
--  v_str := 'AA0BC0DDDBC0XX0BE0F0GGE0F0IJJ0HHI000';
  v_str := 'A0BBB0ACCDE0XXJDE0KKJGE0000GFF0IIHH0';

		stringtoblocks(v_str);
	end;

	procedure allcombinations is
	begin
		for c1 in 0..4 loop
			exit when blocks.count < 1 ;
			continue when not setblock(blocks(0),c1);
			printboard(0);
			
			for c2 in 0..4 loop
				exit when blocks.count < 2 ;
				continue when not setblock(blocks(1),c2);
				printboard(1);

				for c3 in 0..4 loop
					exit when blocks.count < 3 ;
					continue when not setblock(blocks(2),c3);
					printboard(2);

					for c4 in 0..4 loop
						exit when blocks.count < 4 ;
						continue when not setblock(blocks(3),c4);
						printboard(3);

						for c5 in 0..4 loop
							exit when blocks.count < 5 ;
							continue when not setblock(blocks(4),c5);
							printboard(4);

							for c6 in 0..4 loop
								exit when blocks.count < 6 ;
								continue when not setblock(blocks(5),c6);
								printboard(5);

								for c7 in 0..4 loop
									exit when blocks.count < 7 ;
									continue when not setblock(blocks(6),c7);
									printboard(6);

									for c8 in 0..4 loop
										exit when blocks.count < 8 ;
										continue when not setblock(blocks(7),c8);
										printboard(7);

										for c9 in 0..4 loop
											exit when blocks.count < 9 ;
											continue when not setblock(blocks(8),c9);
											printboard(8);

											for c10 in 0..4 loop
												exit when blocks.count < 10 ;
												continue when not setblock(blocks(9),c10);
												printboard(9);

												for c11 in 0..4 loop
													exit when blocks.count < 11 ;
													continue when not setblock(blocks(10),c11);
													printboard(10);

													for c12 in 0..4 loop
														exit when blocks.count < 12 ;
														continue when not setblock(blocks(11),c12);
														printboard(11);

														for c13 in 0..4 loop
															exit when blocks.count < 13 ;
															continue when not setblock(blocks(12),c13);
															printboard(12);

															for c14 in 0..4 loop
																exit when blocks.count < 14 ;
																continue when not setblock(blocks(13),c14);
																printboard(13);

																for c15 in 0..4 loop
																	exit when blocks.count < 15 ;
																	continue when not setblock(blocks(14),c15);
																	printboard(14);

																	for c16 in 0..4 loop
																		exit when blocks.count < 16 ;
																		continue when not setblock(blocks(15),c16);
																		printboard(15);
																		
																	end loop;
																	removeblock(15);
																	
																end loop;
																removeblock(14);

															end loop;
															removeblock(13);
															
														end loop;
														removeblock(12);
														
													end loop;
													removeblock(11);
													
												end loop;
												removeblock(10);
												
											end loop;
											removeblock(9);
											
										end loop;
										removeblock(8);
										
									end loop;
									removeblock(7);
									
								end loop;
								removeblock(6);
								
							end loop;
							removeblock(5);
							
						end loop;
						removeblock(4);
						
					end loop;
					removeblock(3);

				end loop;
				removeblock(2);

			end loop;
			removeblock(1);

		end loop;

		dbms_output.put_line('possible combinations = '||cnt);
		commit;	
	end;   


	function move(a_position in out blocksArrayType, a_board in out gridtype, a_block_id number, a_step number) return boolean is
	canmove boolean;
	begin
		if a_step = 0 then
			return true;
		end if;
		
		if a_position(a_block_id).orientation = '-' then
			canmove := a_position(a_block_id).x + a_step between 0 and  (5 - a_position(a_block_id).length);
		else
		end if;
	end;

	procedure solve(a_position blocksArrayType, a_board gridtype) is
		newposition blocksArrayType;
		newboard gridtype;
		boardstring varchar2(36);
	begin
		boardstring := boardtostring(a_board);
		if steps.exists(boardstring) then
			dbms_output.put_line('error: combination exists.');
		end if;
		steps(boardstring) := a_position;
		newboard := a_board;
		newposition := a_position;		
		
		for i in 0..a_position.count - 1 loop
			for j in -4..4 loop
				if move(newposition,newboard,i,j) then
					if i = 0 and newposition(0).x = 4 then 
						solutionfound;
						steps.delete(boardstring);
						exit;
					elsif j<>0 then
						solve(newposition, newboard);
						newboard := a_board;
						newposition := a_position;
					end if;
				end if;
			end loop;
		end loop;
		
		steps.delete(boardstring);
	end;

BEGIN
	init;
	allcombinations;
END;
/

-- select count(8), length(replace(board,'0',''))  from combos group by length(replace(board,'0','')) order by 2;
-- select * from combos where length(replace(board,'0','')) = 26 order by id;

