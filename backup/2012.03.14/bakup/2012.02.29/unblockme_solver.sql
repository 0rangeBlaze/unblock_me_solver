clear screen
set timing on
set serveroutput on size 10000

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
	type gridcellarray IS TABLE OF varchar2(1) INDEX BY binary_integer;
	type boardtype IS TABLE OF gridcellarray INDEX BY binary_integer;
	type stepstype IS TABLE OF blocksArrayType index by varchar2(36);
	
	blocks blocksArrayType;
	board boardtype;
	block blocktype;
	steps stepstype;
	x number;
	y number;
	cnt number := 0;
	id number := 0;
	v_tmp varchar2(36);


	procedure printstring(a_str varchar2) is
	begin
		for i in 0..5 loop
			dbms_output.put_line(substr(a_str, i*6 + 1 , 6));
		end loop;
		dbms_output.put_line('	');
	end;


  
	function boardtostring(a_board  boardtype) return varchar2 is
	v_str varchar2(36);
	begin
		for i in 0..5 loop
			for j in 0..5 loop
				v_str := v_str || a_board(i)(j);
			end loop;		
		end loop;
	return(v_str);
	end;
	

	procedure checkboard(a_board boardtype, a_blocks blocksarraytype) is
	v_cnt number;
	boardstring varchar2(36);
	wrong boolean := false;
	begin
		boardstring := boardtostring(a_board);
		for i in 0..a_blocks.count -1 loop

			v_cnt := 36 - length(replace(boardstring,a_blocks(i).marker,'')); 
			if v_cnt <> a_blocks(i).length then
				dbms_output.put_line('error : ' || a_blocks(i).marker || ' length = '||a_blocks(i).length || ' onboard = '||v_cnt|| ' board = '||boardstring);
				printstring(boardstring);
				wrong := true;
			end if;

		end loop;
		
		if wrong then
			for i in 0..a_blocks.count -1 loop
				dbms_output.put_line(a_blocks(i).marker || ' x = '||a_blocks(i).x || ' y = '||a_blocks(i).y);
			end loop;
		end if;		
	end;



	procedure removeblock(a_board in out boardtype, a_block blocktype) is
	begin
		for i in 0..5 loop
			for j in 0..5 loop
				if a_board(i)(j) = a_block.marker then
					a_board(i)(j) := '0';
				end if;
			end loop;		
		end loop;
	end;
	
	procedure addblock(a_board in out boardtype, a_block blocktype) is
	begin
		if a_block.orientation = '-' then
			for i in 0..a_block.length - 1 loop
				a_board(a_block.y)(a_block.x + i) := a_block.marker;
			end loop;
		else
			for i in 0..a_block.length - 1 loop
				a_board(a_block.y + i)(a_block.x) := a_block.marker;
			end loop;		
		end if;
	end;
	
	procedure removeblock(a_idx number) is
	begin
		if blocks.count >= a_idx + 1 then
			removeblock(board, blocks(a_idx));
		end if;
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
		addblock(board, blocks(id));
	end;
   
   
	procedure keytoblocks(a_str varchar2) is
  v_x number;
  v_y number;
  v_o varchar2(1);
  v_l number;  
  v_m varchar2(1);
	v_str varchar2(150) := a_str;
  
	begin
		loop
			exit when length(v_str) = 0;
			v_x := substr(v_str,1,1);
			v_y := substr(v_str,2,1);
			v_o := substr(v_str,3,1);
			v_l := substr(v_str,4,1);
			if v_y = 2 and v_o = '|' then
				v_m := 'X';
			end if;	
			registerblock(v_x,v_y,v_l,v_o,v_m);
		end loop;
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
	a_block blocktype;
	begin
		for i in 0..5 loop
			for j in 0..5 loop
				board(i)(j) := '0';
			end loop;		
		end loop;

		v_str :=           'ABBB0C';
		v_str :=  v_str || 'A0DE0C';
		v_str :=  v_str || 'XXDE0C';
		v_str :=  v_str || '00DFGG';
		v_str :=  v_str || '0HHFJ0';
		v_str :=  v_str || '0IIIJ0';

		stringtoblocks(v_str);
		
		for i in 0..blocks.count - 1 loop
			if blocks(i).marker = 'X' then
				a_block := blocks(i);
				blocks(i) := blocks(0);
				blocks(0) := a_block;
				exit;
			end if;
		end loop;
		
	end;


	procedure solutionfound is
	i varchar2(36);
	begin
		dbms_output.put_line('solution : '||steps.count);
		i := steps.first;
		loop
			printstring(i);
			exit when i = steps.last;
			i := steps.next(i);
		end loop;
	end;

	function move(a_position in out nocopy blocksArrayType, a_board in out nocopy boardtype, a_block_id number, a_coord number) return boolean is
		block blocktype := a_position(a_block_id);
		board_bkp boardtype := a_board;
		boardstring varchar2(36);		
	begin

		if block.orientation = '-' then
			if a_coord =  block.x then	return true; end if;
			
			for i in least(block.x, a_coord)..greatest(block.x, a_coord) loop
				if not a_board(block.y)(i) in ('0',block.marker) then return false; end if;	
			end loop;
			removeblock(a_board, block);
			block.x := a_coord;
			addblock(a_board, block);
			
		else
			if a_coord =  block.y then	return true; end if;
			
			for i in least(block.y, a_coord)..greatest(block.y, a_coord) loop
				if not a_board(i)(block.x) in ('0',block.marker) then return false; end if;	
			end loop;
			removeblock(a_board, block);
			block.y := a_coord;
			addblock(a_board, block);
		end if;

		boardstring := boardtostring(a_board);
		if steps.exists(boardstring) then
			a_board := board_bkp;
			return false;
		else
			a_position(a_block_id) := block;
			return true;
		end if;
		
	end;

	

	procedure solve(a_position blocksArrayType, a_board boardtype) is
		newposition blocksArrayType;
		newboard boardtype;
		boardstring varchar2(36);
		v_tmp varchar2(36);
	begin
		boardstring := boardtostring(a_board);
		if steps.exists(boardstring) then
--			dbms_output.put_line('combination exists : '||boardstring);
			return;
		end if;
		steps(boardstring) := a_position;
		newboard := a_board;
		newposition := a_position;		

cnt := cnt + 1;

		for i in 0..newposition.count - 1 loop
			for j in 0..6 - newposition(i).length loop
				if move(newposition,newboard,i,j) then
					if newposition(i).marker = 'X' and newposition(i).x = 4 then 
						solutionfound;
						steps.delete(boardstring);
						return;
					end if;	
					solve(newposition, newboard);
					newboard := a_board;
					newposition := a_position;
-- dbms_output.put_line('- '|| i || ' '|| j || ' ' ||newposition(i).orientation|| ' ' ||newposition(i).x|| ' ' ||newposition(i).y);
				end if;
			end loop;
		end loop;
		
		steps.delete(boardstring);
	end;

BEGIN
	init;
/*
	v_tmp := boardtostring(board);
	printstring(v_tmp);
	
	removeblock(board,blocks(1));
	v_tmp := boardtostring(board);
	printstring(v_tmp);
	
	blocks(1).x := 2;
	addblock(board,blocks(1));
	v_tmp := boardtostring(board);
	printstring(v_tmp);
*/
	solve(blocks, board);
--	dbms_output.put_line('total iterations = '||cnt);
END;
/

-- select count(8), length(replace(board,'0',''))  from combos group by length(replace(board,'0','')) order by 2;
-- select * from combos where length(replace(board,'0','')) = 26 order by id;

