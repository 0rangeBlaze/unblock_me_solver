clear screen
set timing on
set serveroutput on size 3000

DECLARE

	TYPE BlockType IS RECORD (
		x NUMBER(1),
		y NUMBER(1),
		length number(1),
		orientation varchar2(1),
		marker varchar2(1)
	);
	
	type blocksArrayType IS TABLE OF BlockType INDEX BY binary_integer;
	
	TYPE StepType IS RECORD (
		key varchar2(36),
		level number(10),
		parent_id number,
		moved varchar2(1),
		position blocksArrayType
	);
	
	
	type gridcellarray IS TABLE OF varchar2(1) INDEX BY binary_integer;
	type boardtype IS TABLE OF gridcellarray INDEX BY binary_integer;
	type stepstype IS TABLE OF steptype index by binary_integer;
	
	blocks blocksArrayType;
	board boardtype;
	block blocktype;
	steps stepstype;
	x number;
	y number;
	id number := 0;
	v_depth number := 0;
	lvl number := 0;
	v_str varchar2(36);


	procedure printstring(a_str varchar2) is
	begin
		for i in 0..5 loop
			dbms_output.put_line(replace(substr(a_str, i*6 + 1 , 6),'0','.'));
		end loop;
		dbms_output.put_line('	');
	end;

	function boardtostring(a_board  boardtype) return varchar2 is
	v_str varchar2(36);
	begin
		for i in 0..5 loop
			for j in 0..5 loop
				v_str := v_str || a_board(j)(i);
			end loop;		
		end loop;
	return(v_str);
	end;

	
	function boardfromblocks (a_position blocksArrayType) return boardtype is
		a_board boardtype;
		a_block blocktype;
	begin
		for i in 0..5 loop
			for j in 0..5 loop
				a_board(i)(j) := 0;
			end loop;		
		end loop;

		for c in 0..a_position.count - 1 loop
			a_block := a_position(c);
			if a_block.orientation = '-' then
				for i in 0..a_block.length - 1 loop
					a_board(a_block.x + i)(a_block.y) := a_block.marker;
				end loop;
			else
				for i in 0..a_block.length - 1 loop
					a_board(a_block.x)(a_block.y + i) := a_block.marker;
				end loop;		
			end if;
		end loop;
		
    return a_board;
	end;


	function blockstostring(a_position blocksarraytype) return varchar2 is
	begin
		return(boardtostring(boardfromblocks(a_position)));
	end;

/*	
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
   
   
	procedure codedstringtoblocks(a_str varchar2) is
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
*/
   

	function stringtoblocks(a_str varchar2) return blocksarraytype is
  
		v_filler varchar2(1) := '0';
		v_done varchar2(30) := ' ';
		v_m varchar2(1);
		blocks blocksarraytype;
		v_grid_size number := 6;
  
	begin
		for i in 1..v_grid_size * v_grid_size loop
			v_m := substr(a_str, i , 1);
      if v_m <> v_filler and instr(v_done, v_m) = 0 then
			
				blocks(id).x := mod((i - 1),v_grid_size);
				blocks(id).y := trunc((i - 1)/v_grid_size);
				blocks(id).length := v_grid_size * v_grid_size - length(replace(a_str,v_m,''));
				blocks(id).marker := v_m;

				if blocks(id).x < v_grid_size and substr(a_str, i + 1, 1) = blocks(id).marker then
					blocks(id).orientation := '-';
				elsif blocks(id).y < v_grid_size and substr(a_str, i + v_grid_size, 1) = blocks(id).marker then
					blocks(id).orientation := '|';
				else
					raise_application_error(-20000, 'Can not determine block orientation : block = ' || blocks(id).marker);
				end if;

				v_done := v_done || blocks(id).marker;
				id := id + 1;
      end if;
		end loop;
		
		return(blocks);
	end;   


	procedure solutionfound(id number) is
	i number;
	begin
		dbms_output.put_line('solution at level : '||steps(id).level);
		i := id;
		loop
      dbms_output.put_line('moved : '||steps(i).moved);
      printstring(steps(i).key);
      i := steps(i).parent_id;
      exit when i is null;
		end loop;
/*
		i := steps.last;
		loop
			printstring(i);
			exit when i = steps.first;
			i := steps.prior(i);
		end loop;
*/
	end;

	function move(a_position in out nocopy blocksArrayType, a_block_id number, a_coord number) return varchar2 is
		block blocktype := a_position(a_block_id);
		a_board boardtype := boardfromblocks(a_position);
		key varchar2(36);
	begin

		if block.orientation = '-' then
			if a_coord =  block.x then	return null; end if;

			for i in least(block.x, a_coord)..greatest(block.x, a_coord) + block.length - 1 loop
				if not a_board(i)(block.y) in ('0',block.marker) then return null; end if;	
			end loop;

			a_position(a_block_id).x := a_coord;
		else
			if a_coord =  block.y then	return null; end if;

			for i in least(block.y, a_coord)..greatest(block.y, a_coord) + block.length - 1 loop
				if not a_board(block.x)(i) in ('0',block.marker) then return null; end if;	
			end loop;

			a_position(a_block_id).y := a_coord;
		end if;

		key := blockstostring(a_position);
		for i in 0..steps.count - 1 loop
			if steps(i).key = key then
				return null;
			end if;
		end loop;
		
		return key;
		
	end;

	

	procedure solve is
		step steptype;
		id number;
		done boolean;
		position blocksarraytype;
		key varchar2(36);
		
	begin
	
		loop
			done := true;
			dbms_output.put_line(lvl || ' ' ||steps.count);
			for c in 0..steps.count - 1 loop
				if steps(c).level = lvl then
					
					for i in 0..steps(c).position.count - 1 loop
						for j in 0..6 - steps(c).position(i).length loop
              position := steps(c).position;
							key := move(position,i,j);
							if key is not null then
								
								done := false;
								id := steps.count;
								steps(id).key := key;
								steps(id).parent_id := c;
								steps(id).moved := position(i).marker;								
								steps(id).level := lvl + 1;
								steps(id).position := position;

								if substr(steps(id).key,17,2) = 'XX' then 
									solutionfound(id);
									return;
								end if;

							end if;
						end loop;
					end loop;			
				end if;
			end loop;
			
			lvl := lvl + 1;
			exit when done;
		end loop;

	end;

BEGIN
	v_str :=           'ABBB0C';
	v_str :=  v_str || 'A0DE0C';
	v_str :=  v_str || 'XXDE0C';
	v_str :=  v_str || '00DFGG';
	v_str :=  v_str || '0HHFJ0';
	v_str :=  v_str || '0IIIJ0';

  v_str := 'AA0BC0DDDBC0XX0BE0F0GGE0F0IJJ0HHI000';
  v_str := 'A0BBB0ACCDE0XXJDE0KKJGE0000GFF0IIHH0';
  
	steps(0).key:= v_str;
	steps(0).level := 0;
	steps(0).parent_id := null;
	steps(0).position := stringtoblocks(v_str);

	solve;
END;
/
