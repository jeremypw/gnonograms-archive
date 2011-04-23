/*  Copyright (C) 2010-2011  Jeremy Wootten
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * As a special exception, if you use inline functions from this file, this
 * file does not by itself cause the resulting executable to be covered by
 * the GNU Lesser General Public License.
 * 
 *  Author:
 * 	Jeremy Wootten <jeremwootten@gmail.com>
 */
 
 public class Gnonogram_region {

/** A region consists of a one dimensional array of cells, corresponding to a row or column of the puzzle
 Associated with this are:
	1) A list of block lengths (clues)
	2) A 'tag' boolean array for each cell with a flag for each block indicating whether it is still a possible owner and two extra flags - ' is completed' and ' can be empty'
	3) A 'completed blocks' boolean array with a flag for each block indicating whether it is completed.
	4) A status array, one per cell indicating the status of that cell as either UNKNOWN, FILLED (but not necessarily assigned to a completed block, EMPTY, or COMPLETED (assigned to a completed block).
**/
	public bool _is_column;
	public bool _in_error;
	public bool _completed;
	public int _index;
	
	private bool _completed_store;
	private bool[] _completed_blocks;
	private bool[] _completed_blocks_store;
	private bool[,] _tags;
	private bool[,] _tags_store;
	private int [,] _ranges; //format: start,length,unfilled?,complete?
	private int _ncells;
	private int _nblocks;
	private int _block_total; //total cells to be filled
	private int _block_extent; //int.minimum span of blocks, including gaps of 1 cell.
	private int _cycles;
//	private int _pass;
	private int _unknown; 
	private int _filled; 
	private int _can_be_empty_ptr;
	private int _is_finished_ptr;
	private int[] _blocks;
	public My2DCellArray _grid;
	private CellState[] _status;
	private CellState[] _status_store;
	private CellState[] _temp_status;
	private bool _debug;
	public string message;

//=========================================================================	
	public Gnonogram_region (My2DCellArray grid)
	{
		_grid=grid;
		int maxlength=int.max(Resource.MAXCOLSIZE,Resource.MAXROWSIZE);
//		stdout.printf("maxlength %d\n",maxlength);
		_status=new CellState[maxlength]; _status_store=new CellState[maxlength];
		_temp_status=new CellState[maxlength];

// in order that size of class is determined initialize all array variables to maximum possible size
// get weird memory errors otherwise.

		int maxblocks=maxlength/2+2;
//		stdout.printf("maxblocks %d\n",maxblocks);
		
		_ranges=new int[maxblocks,4+maxblocks];
		_blocks=new int[maxblocks];
		_completed_blocks=new bool[maxblocks]; _completed_blocks_store=new bool[maxblocks];
		_tags=new bool[maxlength, maxblocks+2]; _tags_store=new bool[maxlength, maxblocks+2];
		//two extra flags for "can be empty" and "is finished".
		
	}
//=========================================================================	
	public void initialize(int index, bool iscolumn, int ncells, string blocks)
	{
		_index=index;
		_is_column=iscolumn;
		_ncells=ncells;
		_completed=(_ncells==1); //allows debugging of single row
		_in_error=false;
		_block_total=0;
		_block_extent=0;
		_cycles=0;
		_debug=false;
		_unknown=99;
		_filled=99;
		
		int[] tmp_blocks=Utils.block_array_from_clue(blocks);
		_nblocks=tmp_blocks.length;
		_can_be_empty_ptr=_nblocks; //flag for cell that may be empty
		_is_finished_ptr=_nblocks+1; //flag for finished cell (filled or empty?)

		for (int i=0;i<_nblocks;i++)
		{
			_blocks[i]=tmp_blocks[i];
			_block_total=_block_total+tmp_blocks[i];
			_completed_blocks[i]=false;
		}	
		_block_extent=_block_total+_nblocks-1; //last_block == number of gaps.

		for (int i=0;i<_ncells;i++)
		{
			for (int j=0; j<_nblocks; j++) _tags[i,j]=false;
			//Start with no possible owners and can be empty.
			_tags[i,_can_be_empty_ptr]=true;
			_tags[i,_is_finished_ptr]=false;
			_status[i]=CellState.UNKNOWN;
			_temp_status[i]=CellState.UNKNOWN;
		}
	}

//======================================================================
	public void save_state()
	{
//		stdout.printf("%d save state\n",_index);
//		stdout.printf("ncells %d, nblocks %d\n",_ncells,_nblocks); 

		for (int i=0;i<_ncells;i++)
		{
			_status_store[i]=_status[i];
			for (int j=0; j<_nblocks+2; j++) _tags_store[i,j]=_tags[i,j];
		}
		for (int j=0; j<_nblocks; j++) _completed_blocks_store[j]=_completed_blocks[j];
		
		_completed_store=_completed;
	}
//======================================================================
	public void restore_state()
	{	//stdout.printf("%d restore state\n",_index);
		for (int i=0;i<_ncells;i++)
		{
			_status[i]=_status_store[i];
			for (int j=0; j<_nblocks+2; j++) _tags[i,j]=_tags_store[i,j];
		}
		for (int j=0; j<_nblocks; j++) _completed_blocks[j]=_completed_blocks_store[j];
		
		_completed=_completed_store;
		_in_error=false; message="";
	}
//======================================================================
	public bool solve(bool debug=false)
	{
		/**cycles through ploys until no further changes can be made
		ignore single cell regions for testing purposes ...
		* */
		message=""; _debug=debug;
		if (_completed) return false; 
		
		bool made_changes=false;
		//	bool still_changing=false;
		get_status();
		//still_changing=totals_changed(); //always true when _cycles==0

		//if (!still_changing) return false;

		if(_cycles>0 && !totals_changed()) return false; //no change since last visit
		bool still_changing=true;		
		_completed=(count_cell_state(CellState.UNKNOWN)==0); //could have been completed externally
		int count=0;
		while (!_completed && count<20) //count guards against infinite loops
		{
			_cycles++; count++;
			//stdout.printf("Region %d cycle %d \n",_index,_cycles);
			if (_cycles==1) initial_fix(); //TO DO - eliminate this step
			else
			{
				still_changing=full_fix();
				//full_fix2();
			}
			if (_in_error) break;
			
			tags_to_status();		 //MAY NEED THIS???			
			//still_changing=totals_changed(); //always true when _cycles==1
			//stdout.printf("Region %d cycle %d still changing %s\n",_index,_cycles, still_changing.to_string());
			//if (still_changing)
			if (totals_changed())
			{
				if(_in_error) break;
				else made_changes=true;
				//_completed=(count_cell_state(CellState.UNKNOWN)==0);
				//if(_completed && (count_cell_state(CellState.COMPLETED)+count_cell_state(CellState.FILLED))!=_block_total)
				// {
				//	record_error("Total filled check", "Wrong number of filled cells",false);
			}
			else break;
		}
		if ((made_changes && !_in_error)||debug) put_status(debug);
		if (count==20) stdout.printf("Excessive looping in region %d\n",_index);
		
		return made_changes;
	}
//======================================================================
	private void initial_fix()
	{//stdout.printf("initial_fix\n");
		if (_blocks[0]==0)
		{
			_completed_blocks[0]=true;
			_completed=true;
		}
		else
		{ //if (_debug) return;
			int freedom=_ncells-_block_extent;			
/*
 *			int start=0;
			int length=0;
			
			for (int i=0; i<_nblocks; i++)
			{
				length=_blocks[i]+freedom;			
				for (int j=start; j<start+length; j++) _tags[j,i]=true;
				if (freedom<_blocks[i])
				{
					set_range_owner(i,start+freedom,_blocks[i]-freedom,true);
				}
				start=start+_blocks[i]+1; //leave a gap between blocks
			}
*/

			fix_blocks_in_range(0,_nblocks-1,0,_ncells);
			if (freedom==0) _completed=true;
		}
	}
//======================================================================
	private bool full_fix()
	{	if (_debug) stdout.printf("\n\nfull_fix\n");
		//if (_debug) return false;
		status_to_tags();

		//stdout.printf("Possibilities audit\n");
		if (possibilities_audit()||_in_error||tags_to_status()) {
			//stdout.printf("possibilities audit made change\n");
			return true;}
		//tags_to_status();
		//stdout.printf("Only_possibility\n");
		if (only_possibility()||_in_error||tags_to_status()) {
			//stdout.printf("only possibility made change\n");
			return true;}
		//stdout.printf("Free cell audit\n");
		if (free_cell_audit()||_in_error||tags_to_status()) {
			//stdout.printf("free cell audit audit made change\n");
			return true;}					
		//stdout.printf("Do edge(1)\n");
		if (do_edge(1)||_in_error||tags_to_status()) {
			//stdout.printf("do edge forwards made change\n");
			return true;}
		
		//stdout.printf("Do edge(-1)\n");
		if (do_edge(-1)||_in_error||tags_to_status()) {
			//stdout.printf("do edge backwards made change\n");
			return true;}
		//stdout.printf("Filled subregion\n");
		if (filled_subregion_audit()||_in_error||tags_to_status()) {
			//stdout.printf("filled sub region made change\n");
			return true;}
		//stdout.printf("Fill_gaps\n");
		if (fill_gaps()||_in_error||tags_to_status()) {
			//stdout.printf("fill gaps made change\n");
			return true;}
				
		//stdout.printf("Available range audit\n");
		if (available_range_audit()||_in_error||tags_to_status()) {
		//	//stdout.printf("available range audit made change\n");
			return true;}
						
		return false;
	}
//======================================================================

//======================================================================
	private bool filled_subregion_audit() {
//find a range of filled cells not completed and see if can be associated
// with a unique block.
	if(_debug) stdout.printf("Filled subregions audit\n");
		bool changed=false;
		int idx=0;
		int length;
		
		while (idx<_ncells)
		{//find a filled sub-region
		
			if (skip_while_not_status(CellState.FILLED,ref idx))
			{
				//idx points to first filled cell or returns false
				if (_tags[idx,_is_finished_ptr]) {idx++; continue;}//ignore if completed already
				
				length=count_next_state(CellState.FILLED, idx);//idx not changed
				if(_debug) stdout.printf(@"filled subregion start $idx length $length\n");
				//is this region capped?
				if ((idx==0 || _status[idx-1]==CellState.EMPTY) && (idx==_ncells-1 || _status[idx+1]==CellState.EMPTY))
				{// assigned block must fit exactly
					if(_debug) stdout.printf("Region is already capped\n");
					assign_and_cap_range(idx,length);
					changed=true;
				}
				else
				{
					int largest=find_largest_possible_in_cell(idx);
					if(_debug) stdout.printf(@"filled subregion largest possible $largest \n");
					if (largest==length)
					{//there is **at least one** largest block that fits exactly
					// this region must therefore be complete
						assign_and_cap_range(idx,length);
						changed=true;
					}
					else
					{//remove blocks that are smaller than length from this region and one cell either side
					
						for(int i=idx-1;i<=idx+length;i++)
						{						
							if (i<0||i>_ncells-1) continue;
							
							for (int bl=0;bl<_nblocks;bl++)
							{							
								if (_tags[i,bl] && _blocks[bl]<length) _tags[i,bl]=false;
							}
						}
					}
				}
				idx+=length;//move past block
			}
			else break;
		}
		return changed;	
	}
//======================================================================
	private bool fill_gaps()
	{	// Find unknown gap between filled cells and complete accordingly.
		// Find an owned cell followed by an unknown gap
		// Find next filled cell - if same owner complete between 

		bool changed=false;
		for (int idx=0; idx<_ncells-2; idx++)
		{			
			if (_status[idx]!=CellState.FILLED) continue;
			if (_status[idx+1]!=CellState.UNKNOWN) continue;
			if (!one_owner(idx))
			{//see if single cell gap which can be marked empty because to fill it would create a block larger than any permissible.
				if(_status[idx+2]!=CellState.FILLED) continue;
				int blength=count_next_state(CellState.FILLED,idx+2, true)+count_next_state(CellState.FILLED,idx,false)+1;
				bool must_be_empty=true;
				for (int bl=0; bl<_nblocks; bl++)
				{
					if(_tags[idx,bl] && _blocks[bl]>=blength) {must_be_empty=false;break;}
				}
				//no permissible blocks large enough
				if (must_be_empty){set_cell_empty(idx+1); changed= true;} 
			}	
			else
			{
				int cell1=idx; //start of gap
				idx++;
				//skip to end of gap
				while (idx<_ncells-1 && _status[idx]==CellState.UNKNOWN) idx++;
				
				if (_status[idx]!=CellState.FILLED) continue; //gap ends with empty cell
				
				int owner;
				if (same_owner(cell1,idx, out owner))
				{
					changed=set_range_owner(owner,cell1,idx-cell1+1)||changed;
				}
			}
		}
		return changed;
	}
//======================================================================
	private bool possibilities_audit()
	{	//find a unique possible range for block if there is one.
		//eliminates ranges that are too small
		//stdout.printf("possibilities audit\n");
		//log_state();
		bool changed=false;
		
		int start,length,count;
		
		for (int i=0;i<_nblocks;i++)
		{			
			if (_completed_blocks[i]) continue; //skip completed block
			
			start=0;length=0;count=0;
			for (int idx=0;idx<_ncells;idx++)
			{				
				if (count>1) break; //try next block
				if (!_tags[idx,i]||_tags[idx,_is_finished_ptr]) continue;

				int s=idx; //first cell with block i as possible owner
				int l=count_next_owner(i,idx); //length of contiguous cells having this block (i) as a possible owner.
				//int s=idx; //cell after end of available range ????
				
				if (l<_blocks[i])
				{//cant be here
					remove_block_from_range(i,s,l);
				}
				else
				{
					length=l;
					start=s;
					count++;
				}
				idx+=l-1; //allow for incrementing on next loop
			}
			
			if (count!=1) continue; //no unique range found
			else {//at least some cells can be assigned but
			//this range not proved exclusive to this block
				//stdout.printf(@"poss audit about to fix block i=$i start=$start length=$length\n");
				changed=fix_block_in_range(i,start,length,false)||changed;
			}
		}
		//log_state();
		return changed;
	}
//=========================================================================	
	private void assign_and_cap_range(int start, int length)
	{	//make list of possible blocks with right length in max_blocks[]
		//record which is first and which last (in order).
		//always changes at least on cell status
		//stdout.printf(@"Assign and cap start $start length $length\n");
		if(_debug) stdout.printf(@"Assign and cap start $start length $length\n");
		int count=0;
		int[] max_blocks=new int[_nblocks];
		int first=_nblocks;
		int last=0;
		
		for (int i=0;i<_nblocks;i++)
		{			
			if (_completed_blocks[i]) continue;
			if (_blocks[i]!=length) continue;
			if (!_tags[start,i]) continue;
			
			max_blocks[count]=i;
			count++;
			
			if (i<first) first=i;
			if (i>last) last=i;
		}

		if(_debug)stdout.printf(@"count $count\n");
		if(count==0) return; //not necessarily an error
		if (count==1)
		{//unique owner
			set_block_complete_and_cap(max_blocks[0],start);
		}
		else
		{//ambiguous owner
			//delete out of sequence blocks before end of range
			for (int i=last;i<_nblocks;i++)
			{
				remove_block_from_cell_to_end(i,start+length-1,-1);
			}		
			//delete out of sequence blocks after start of range
			for (int i=0;i<=first;i++)
			{
				remove_block_from_cell_to_end(i,start,1);
			}
			//for each possible mark as possible owner of subregion (not exclusive)
			for (int i=0;i<count;i++)
			{
				set_range_owner(max_blocks[i],start,length,false);
			}
			//remove as possible owner blocks between first and last that are wrong length
			for (int i=first+1;i<last;i++)
			{
				if (_blocks[i]==length) continue;
				remove_block_from_range(i,start,length,1);
			}
			// cap range
			if (start>0) set_cell_empty(start-1);
			if (start+length<_ncells) set_cell_empty(start+length);
		}
	}	
//======================================================================
	private bool only_possibility()
	{ //find an unfinished cell with only one possibility

		bool changed=false;
		int owner;
		int length;
		int start;
		
		for (int i=0;i<_ncells;i++)
		{			
			if (_tags[i,_is_finished_ptr]) continue;
			
			if (_status[i]==CellState.FILLED && one_owner(i))
			{
				//find the owner
				
				for (owner=0;owner<_nblocks;owner++)
				{					
					if (_tags[i,owner]) break;
				}
				
				length=_blocks[owner];
				start=i-length;
				if (start>=0) remove_block_from_cell_to_end(owner,start,-1);
				
				start=i+length;
				if (start<_ncells) remove_block_from_cell_to_end(owner,start,+1);					
			}
		}
		return changed; //always false - only changes tags
	}

//======================================================================
	private bool free_cell_audit()
	{ 
		int free_cells=count_cell_state(CellState.UNKNOWN);
		
		if (free_cells==0) return false;
		
		int filled_cells=count_cell_state(CellState.FILLED);
		int completed_cells=count_cell_state(CellState.COMPLETED);
		int to_locate=_block_total-filled_cells-completed_cells;
		
		if (free_cells==to_locate)
		{//free_cells>0
			for (int i=0;i<_ncells;i++)
			{
				if (_status[i]==CellState.UNKNOWN) set_cell_complete(i);
			}
			
			for (int i=0;i<_nblocks;i++) _completed_blocks[i]=true;
			
			return true;
		}
		else if (to_locate==0)
		{
			for (int i=0;i<_ncells;i++)
			{
				if (_status[i]==CellState.UNKNOWN) set_cell_empty(i);
			}
			return true;
		}

		return false;
	}

//======================================================================
	private bool do_edge(int direction)
	{
		//1=forward -1=backward
		int idx; //pointer to current cell
		int blocknum; //current block
//		int blength; // length of current block
		int limit; //first out of range value of idx depending on direction
		bool changed=false; //tags changed?
		bool dir=(direction>0);
		
		if (dir)
		{
			idx=0;
			blocknum=0;
			limit=_ncells;
		}
		else
		{
			idx=_ncells-1;
			blocknum=_nblocks-1;
			limit=-1;
		}
		
		if (!find_edge(ref idx,ref blocknum,limit,direction))	return false;
				
//		blength=_blocks[blocknum];
//		for (int i=0; i<_nblocks;i++) stdout.printf(@"$(_blocks[i]), ");
//		stdout.printf(@"blength $blength\n");

		if (_status[idx]==CellState.FILLED)
		{ //start of unassigned filled block
				set_block_complete_and_cap(blocknum,idx,direction);
				changed=true;
		}
		else
		{// see if filled cell in range of first block and complete after that
			int edge_start=idx;
			int fill_start=-1;
			int blength = _blocks[blocknum];
			int blocklimit=(dir? idx+blength : idx-blength);
			
			if (skip_while_not_status(CellState.FILLED,ref idx,blocklimit,direction))
			{
				fill_start=idx;
				
				while (idx!=blocklimit)
				{
					if (_status[idx]==CellState.UNKNOWN)
					{
						set_cell_owner(idx,blocknum);
						changed=true;
					}
					
					if (dir) idx++;
					else idx--;
				} 
				//idx now points to cell after earliest possible end of block
				// if this is a filled cell then first cell in range must be empty
				// continue until an unfilled cell found setting cells at beginning of 
				//range empty
				while (idx!=blocklimit && _status[idx]==CellState.FILLED)
				{
					set_cell_owner(idx,blocknum);
					set_cell_empty(edge_start);
					changed=true;

					if (dir) {idx++; edge_start++;}
					else {idx--; edge_start--;}
				}
				//if a fillable cell was found then fill_start>0
				if (fill_start>0)
				{//delete block  than block length from where filling started
					idx= dir ? fill_start+blength : fill_start-blength;
					
					if (idx>=0 && idx<_ncells) remove_block_from_cell_to_end(blocknum,idx,direction);
				}
			}
		}
		return changed;
	}
//=========================================================================
	private bool find_edge(ref int idx,ref int blocknum, int limit, int direction)
	{//stdout.printf(@"find edge index $idx blocknum $blocknum limit $limit\n");
		bool dir=(direction>0);
		bool found=false;
		
		for (int i=idx; (dir ? i<limit : i>limit); (dir ? i++ : i--))
		{			
			if (_status[i]==CellState.EMPTY) continue;
			//now pointing at first cell of filled or unknown block after edge
			if (_tags[i,_is_finished_ptr])
			{//skip to end of finished block
				i = (dir ? i+_blocks[blocknum]-1 : i-_blocks[blocknum]+1);
				//now pointing at last cell of filled block
				if (dir) blocknum++;
				else blocknum--;
				
				continue;
			}
			
			idx=i;
			found=true;
			break;
		}
		//stdout.printf(@"leaving find edge blocknum = $blocknum found = $found\n");
		return found;
	}
//======================================================================
	private bool available_range_audit()
	{//TODO generalise to deal with more than one block per range (number of available blocks greater than number of available ranges
		
		int ranges;
		int nblocks;
		//bool changed=false;
		//log_state();
		
		ranges=count_available_ranges(); //puts into _ranges[] - available ranges only
		//only counts incomplete ranges - assumes all blocks that can be assigned already have been - otherwise error occurs.
		//stdout.printf(@"Available ranges $ranges\n");
		//a range is contiguous unknown or filled cells between empty cells

		int[] blocks=blocks_available();
		nblocks=blocks.length;
		//stdout.printf(@"Available blocks $nblocks\n");
		
		if (nblocks!=ranges || nblocks<2) return false;
	// only deals with case where must be one block per range
		
		//can more than one block fit? if not fix in range
		bool unique=true;
		for (int r=0; r<ranges; r++)
		{//can the rth range accomodate the rth available block and the one before or the one after?
			if ((r<ranges-1) &&  (_ranges[r,1]>=_blocks[blocks[r]]+_blocks[blocks[r+1]]+1)
				||
				(r>0) && (_ranges[r,1]>=_blocks[blocks[r]]+_blocks[blocks[r-1]]+1)
				)
			{
				//cannot uniquely assign blocks to ranges
				unique=false; 	break;
			}
		}
		
		if (!unique) return false;
		else
		{	
			for (int r=0; r<ranges; r++)
			{
				if (_blocks[blocks[r]]>_ranges[r,1])
				{
					stdout.printf("BUG:  available range audit - block too large\n");
					//this is a bug not necessarily a fatal error - needs fixing tho
					//do not make changes in these circumstances
					return false;
				}
			}
			for (int r=0; r<ranges; r++)
			{
					fix_block_in_range(blocks[r],_ranges[r,0],_ranges[r,1]);				
			}
			return true;
		}
		//log_state();
		//return false; 
	}

//======================================================================
// END OF PLOYS
// HELPER FUNCTIONS FOLLOW
//======================================================================

//======================================================================
	
	private bool skip_while_not_status(CellState cs, ref int idx, int limit=_ncells, int direction=1)
	{
// increments/decrements idx until cell of required state
// or end of range found.
//returns true if cell with status cs was found
		bool dir=(direction>0);
		
		for (int i=idx; (dir ? i<limit : i>limit); (dir ? i++ : i--))
		{	
			if (_status[i]==cs)
			{
				if (i>=0 && i<_ncells)
				{	idx=i;
					return true;
				}
				else
				{
					_in_error=true; message="Skip while not status - idx out of range\n";
					return false;
				}
					
			}
		}	
		return false;	
	}
//======================================================================
	private int count_next_state(CellState cs, int idx, bool forwards=true)
	{
// count how may consecutive cells of state cs starting at given index idx (inclusive)?
		int count=0;
		if (forwards && idx>=0)
		{
			while ( _status[idx]==cs && idx<_ncells) {
				count++;
				idx++;
			}
		}
		else if (!forwards && idx<_ncells)
		{
			while ( _status[idx]==cs && idx>=0) {
				count++;
				idx--;
			}
		}
		else {_in_error=true; message="count_next_state idx invalid\n";}
		return count;
	}
//======================================================================
	private int count_next_owner(int owner, int idx)
	{
// count how may consecutive cells with owner possible starting at given index idx?
		int count=0;
		if (idx>=0)
		{
			while ( _tags[idx,owner] &&
					!_tags[idx,_is_finished_ptr] &&
					 idx<_ncells) {
				count++;
				idx++;
			}
		}
		else {_in_error=true;message="count_next_owner idx negative\n";}
		
		return count;
	}	
//======================================================================
	private int count_owners_and_empty(int cell) {
// how many possible owners?  Does include can be empty tag!
		int count=0;
		
		if (invalid_data(cell)) {_in_error=true;message="count_owners_and_empty invalid data\n";}
		else
		{	
			for (int j=0;j<_nblocks; j++) {

				if (_tags[cell,j]) count++;
			}
			
			if (_tags[cell,_can_be_empty_ptr]) count++;
		}
		if (count==0){_in_error=true; message="count owners and empty - count is zero\n";}
		return count;
	}	
//======================================================================
	private int count_cell_state(CellState cs) {
		//how many times does state cs occur in range.
		int count=0;
		for (int i=0;i<_ncells; i++)
		{
			if (_status[i]==cs) count++;
		}
		return count;
	}
//======================================================================
	private int count_available_ranges() {
// determine location of ranges of unknown or filled cells and store in _ranges[,]
// _ranges[ ,2] indicates contains filled, _ranges[ ,3] indicates contains unknown
		int range=0, start=0, length=0, idx=0;
		while (idx<_ncells)
		{
			length=0;
			start=idx;
			_ranges[range,0]=start;
			_ranges[range,2]=0;
			_ranges[range,3]=0;
			
			while (_status[idx]!=CellState.EMPTY && idx<_ncells)
			{					
				if (!_tags[idx,_can_be_empty_ptr])
				{
					_ranges[range,2]++;//contains filled cell
				}
				else _ranges[range,3]++; //contains unknown cell
				
				idx++; length++;
			}
			
			if (length>0 && _ranges[range,3]!=0) //not completely filled yet
			{
				_ranges[range,1]=length;
				range++;
			}
			
			while (_status[idx]==CellState.EMPTY && idx<_ncells) idx++; //skip to beginning of next range
		}
		return range;
	}
//======================================================================
	private int[] blocks_available() {
	//array of incomplete block indexes
		int[] blocks = {};
		for (int i=0; i<_nblocks; i++)
		{	
			if (!_completed_blocks[i]) blocks+=i;
		}
 		return blocks;
	}
//=========================================================================	
	private bool same_owner(int cell1, int cell2, out int owner) {
//checks if both the same single possible owner.  
//return true if same owner
//if true, 'owner' is initialised
		int count=0;
		owner=0;
		
		if (cell1<0||cell1>=_ncells||cell2<0||cell2>=_ncells)
		{
			_in_error=true; message="same_owner cell - out of range\n";
		}
		else
		{
			for (int i=0; i<_nblocks; i++)
			{	
				if ((_tags[cell1,i]!=_tags[cell2,i])|| count>1)
				{
					count=0;
					break;
				}
				else if (_tags[cell1,i])
				{
					count++;
					owner=i;
				}
			}
		}
		return count==1;
	}
//======================================================================
	private bool one_owner(int cell) {
// if only one possible owner (if not empty) then return true 
		int count=0;
		for (int i=0; i<_nblocks; i++)
		{	
			if (_tags[cell,i]) count++;
			if (count>1) break;
		}
		return count==1;
	}
//=======================================================================
	private bool fix_block_in_range(int block, int start, int length,bool exclusive=true) {
// block must be limited to range
//stdout.printf(@"fix block in range: block $block start $start length $length exclusive $exclusive\n");
		bool changed=false;
		
		if (invalid_data(start,block, length)) {
			_in_error=true; message="fix block in range - invalid data\n";
		}
		else
		{
			int block_length=_blocks[block];
			int freedom = length-block_length;

			if (freedom<0) {record_error("Fix block in range", "block longer than range",false); return false;}
			
			if (freedom<block_length)
			{
				if (freedom==0)
				{
					set_block_complete_and_cap(block,start);
					changed=true;
				}
				else set_range_owner(block,start+freedom,block_length-freedom,true);
			}
		}
		return changed;
	}
//=======================================================================	
	private bool fix_blocks_in_range(int first_block, int last_block, int start, int length)
	{
// blocks must be limited to range, range must not contain empty cells
		if (_debug) stdout.printf(@"old fix blocks in range: first block $first_block last block $last_block start $start length $length\n");
		bool changed=false;
		if (first_block<0||first_block>_nblocks||last_block<0||last_block>_nblocks)
		{
			record_error("Fix_blocks_in_range","Invalid block number", false);
			return false;
		}
		int range_start=start, range_end=start+length;
		int block_extent=0;
		for (int b=first_block; b<=last_block;b++) block_extent+=(_blocks[b]+1);
		block_extent--; //minimum space required by blocks
		if (_debug) stdout.printf(@"Block extent $block_extent\n");
		int freedom=length-block_extent;			
		int idx=start;
		for (int b=first_block; b<=last_block; b++)
		{
			for (int j=range_start; j<range_end; j++) {_tags[j,b]=false;}
			int blength=_blocks[b]+freedom;
			//set as possible owner if cell not marked empty		
			for (int j=idx; j<idx+blength; j++) _tags[j,b]=(_status[j]!=CellState.EMPTY);
			if (freedom<_blocks[b])
			{
				changed=set_range_owner(b,idx+freedom,_blocks[b]-freedom,true)||changed;
			}
			idx=idx+_blocks[b]+1; //leave a gap between blocks
		}

		return changed;
	}
//======================================================================
	private int find_largest_possible_in_cell(int cell)
	{
// find the largest incomplete block possible for given cell
		int max_size=-1;
		for (int i=0;i<_nblocks;i++)
		{	
			if (_completed_blocks[i]) continue;// ignore complete block
			if (!_tags[cell,i]) continue; // not possible
			if (_blocks[i]<=max_size) continue; // not largest
			max_size=_blocks[i]; //update largest
		}
		return max_size;
	}	
//======================================================================
	private void remove_block_from_cell_to_end(int block, int start,int direction=1)
	{
//remove block as possibility after/before start
//bi-directional forward=1 backward =-1
//if reverse direction then equivalent forward range is used
//only changes tags

		int length=direction>0 ? _ncells-start : start+1;
		start=direction>0 ? start : 0;
		remove_block_from_range(block,start,length);
	}
//======================================================================
	private void remove_block_from_range(int block, int start, int length, int direction=1)
	{
//remove block as possibility in given range
//bi-directional forward=1 backward =-1
//if reverse direction then equivalent forward range is used
//only changes tags

		if (direction<0) start=start-length+1;
		if (invalid_data(start,block, length))
		{
			_in_error=true; message="remove block from range - invalid data\n";
		}
		else
		{
			for (int i=start; i<start+length; i++) _tags[i,block]=false;
		}
	}
//======================================================================
	private void set_block_complete_and_cap(int block, int start, int direction=1)
	{
		//returns true - always changes a cell status if not in error
		//stdout.printf(@"set block complete and cap: block $block start $start direction $direction\n");
		int length=_blocks[block];

		if (direction<0) start=start-length+1;
		if (invalid_data(start,block, length))
		{
			_in_error=true; message="set_block_complete_and_cap - invalid data\n"; return;	
		}
		
		if (_completed_blocks[block]==true && _tags[start,block]==false)
		{
			_in_error=true; message="set_block_complete_and_cap - contradiction - completed but not filled\n"; return;
		}
		
		_completed_blocks[block]=true;
		set_range_owner(block,start,length);
		
		if (start>0) set_cell_empty(start-1);
		if (start+length<_ncells) set_cell_empty(start+length);
		
		for (int cell=start; cell<start+length; cell++) set_cell_complete(cell);
		//=======taking into account minimum distance between blocks.
		// constrain the preceding blocks if this are at least two
		int l;
		if (block>1) //at least third block
		{
			l=0;
			for (int bl=block-2;bl>=0;bl--)
			{
				l=l+_blocks[bl+1]+1;// length of exclusion zone for this block
				remove_block_from_range(bl,start-2,l,-1);
			}
		}
		// constrain the following blocks if there are at least two
		if (block<_nblocks-2)
		{
			l=0;
			for (int bl=block+2;bl<=_nblocks-1;bl++)
			{
				l=l+_blocks[bl-1]+1;// length of exclusion zone for this block
				remove_block_from_range(bl,start+length+1,l,1);
			}
		}
	}
//======================================================================
	private bool set_range_owner(int owner, int start, int length, bool exclusive=true, bool can_be_empty=true)
	{
		if (_debug) stdout.printf(@"set range owner start=$start length=$length exclusive $exclusive\n");
		bool changed=false;
		if (invalid_data(start,owner,length))
		{
			_in_error=true; message="set_range_owner - invalid data\n";
			return false;
		}
		else
		{			
			int block_length=_blocks[owner];
			for (int cell=start; cell<start+length; cell++)
			{
				changed = set_cell_owner(cell,owner,exclusive,can_be_empty)||changed; //this checks owner valid
			}
			
			if (exclusive)
			{
				//remove block and out of sequence from regions out of reach if exclusive
				if (block_length<length)
				{
					_in_error=true; message="set_range_owner - contradiction - range too big for owner\n"; return false;
				}
				
				if (start+length-block_length-1>=0) //earliest start point of this block
				{				
					remove_block_from_cell_to_end(owner,start+length-block_length-1,-1);
				}

				
				if (start+block_length<_ncells) //latest end point
				{				
					remove_block_from_cell_to_end(owner,start+block_length);
				}

				int earliest_end=start+length;
				for (int bl=_nblocks-1;bl>owner;bl--) //following blocks cannot be earlier
				{
					remove_block_from_cell_to_end(bl,earliest_end,-1);
				}

				int latest_start=start-1;
				for (int bl=0;bl<owner;bl++) //preceding blocks cannot be later
				{
					remove_block_from_cell_to_end(bl,latest_start);
				}
			}
		}
		return changed;
	}
//======================================================================
	private bool set_cell_owner(int cell, int owner, bool exclusive=true, bool can_be_empty=true)
	{ if (_debug) stdout.printf(@"set cell owner cell=$cell owner=$owner exclusive=$exclusive\n");
		bool changed=false; 
		if (invalid_data(cell,owner))
		{
			_in_error=true; message=@"set_cell_owner - cell $cell invalid data\n";
		}
		else if (_status[cell]==CellState.EMPTY) {}// do nothing - not necessarily an error
		
		else if (_status[cell]==CellState.COMPLETED && _tags[cell,owner]==false)
		{
			record_error("set_cell_owner",@"contradiction cell $cell filled but cannot be owner");
		}
		else
		{
			if (exclusive)
			{
				_status[cell]=CellState.FILLED; changed=true;
				_tags[cell,_can_be_empty_ptr]=false;
				if(!can_be_empty)
				{
					_tags[cell,_can_be_empty_ptr]=false;
				}
				for (int i=0; i<_nblocks; i++) _tags[cell,i]=false;
			}
			_tags[cell,owner]=true;
		}
		return changed;
	}
//======================================================================
	private void set_cell_empty(int cell)
	{
		if (invalid_data(cell))
		{
			record_error("set_cell_empty",@"cell $cell invalid data");
		}
		else if (_tags[cell,_can_be_empty_ptr]==false)
		{
			record_error("set_cell_empty",@"cell $cell cannot be empty");
		}
		
		else if (cell_filled(cell)) {
			record_error("set_cell_empty",@"cell $cell is filled");
		}
		else
		{
			for (int i=0; i<_nblocks; i++) _tags[cell,i]=false;
			
			_tags[cell,_can_be_empty_ptr]=true;
			_tags[cell,_is_finished_ptr]=true;
			_status[cell]=CellState.EMPTY;
		}
	}
//======================================================================
	private void set_cell_complete(int cell)
	{
		if (_status[cell]==CellState.EMPTY)
		{
			record_error("set_cell_complete",@"cell $cell already set empty");
		}
		
		_tags[cell,_is_finished_ptr]=true;
		_tags[cell,_can_be_empty_ptr]=false;
		_status[cell]=CellState.COMPLETED;
	}
//======================================================================
	private bool invalid_data(int start, int block=0, int length=1)
	{
		return (start<0||start>=_ncells||length<1||start+length>_ncells||block<0||block>_nblocks); 
	}
//======================================================================
	private bool cell_filled(int cell)
	{
		return (_status[cell]==CellState.FILLED||_status[cell]==CellState.COMPLETED);
	}
//======================================================================
	private bool totals_changed()
	{
//has number of filled or unknown cells changed?
		if (_cycles==0) return true;
//forces fullfix even if initial fix does not make changes on first visit
// and cells have been set by intersecting ranges.

		bool changed=false;
		int unknown=count_cell_state(CellState.UNKNOWN);
		int filled=count_cell_state(CellState.FILLED);
		
		if (_unknown!=unknown || _filled!=filled)
		{
			changed=true;
			_unknown=unknown;
			_filled=filled;
			
			if (_filled>_block_total) record_error("totals changed","too many filled cells");
			else if (unknown==0) _completed=true;
		}
		
		return changed;
	}
//======================================================================
	private void get_status()
	{//stdout.printf("get status\n");
//transfers cell statuses from grid to internal range status array

		_grid.get_array(_index,_is_column, ref _temp_status);
		
		for (int i=0; i<_ncells; i++)
		{			
			switch (_temp_status[i])
			{				
				case CellState.UNKNOWN :
					break;
					
				case CellState.EMPTY :
				
					//if (cell_filled(i))
					if (!_tags[i,_can_be_empty_ptr])
					{
						record_error("get_status", @"cell $i cannot be empty");
					}
					else
					{	_status[i]=CellState.EMPTY;
						foreach (bool t in _tags) t=false;
						_tags[i,_can_be_empty_ptr]=true;
						_tags[i,_is_finished_ptr]=true;
					}					
					break;
					
				case CellState.FILLED :
					//dont overwrite COMPLETE status
					if (_status[i]==CellState.EMPTY)
					{
						record_error("get_status", @"cell $i cannot be filled");
					}
					else if (_status[i]!=CellState.COMPLETED)
					{
						_status[i]=CellState.FILLED;
						_tags[i,_can_be_empty_ptr]=false;
					}
					
					break;
					
				default : break;
			}
		}
	}
//======================================================================
	private void put_status(bool debug=false)
	{//stdout.printf("put status\n");
		if (debug) {record_error("DEBUG", "",true); }
		
		for (int i=0;i<_ncells; i++)
		{
			_temp_status[i]=(_status[i]==CellState.COMPLETED ? CellState.FILLED : _status[i]);
		}
		_grid.set_array(_index, _is_column, _temp_status);
	}
//======================================================================
	private void status_to_tags()
	{//stdout.printf("status to tags\n");
		for(int i=0;i<_ncells;i++)
		{			
			switch (_status[i])
			{				
				case CellState.COMPLETED :
					_tags[i,_is_finished_ptr]=true;
					_tags[i,_can_be_empty_ptr]=false;
					break;
					
				case CellState.FILLED :
					_tags[i,_can_be_empty_ptr]=false; 
					break;
					
				case CellState.EMPTY :
				
					for (int j=0;j<_nblocks;j++) _tags[i,j]=false;
					
					_tags[i,_can_be_empty_ptr]=true;
					_tags[i,_is_finished_ptr]=true;
					break;
					
				default : break;
			}
		}
		//stdout.printf("leaving status to tags\n");
	}
//======================================================================
	private bool tags_to_status()
	{if(_debug)stdout.printf("tags to status\n");
		bool changed=false;
		for (int i=0;i<_ncells; i++)
		{	
			// skip cells not unknown or with more than one possibility (including empty)
			if (_status[i]!=CellState.UNKNOWN||count_owners_and_empty(i)>1) continue;
			changed=true;
			//Either the 'can be empty' flag is set and there are no owners (ie cell is empty) or there is one owner.
			if (_tags[i,_can_be_empty_ptr]){
				//stdout.printf(@"Empty $i");
				_status[i]=CellState.EMPTY; _tags[i,_is_finished_ptr]=true;}
			else {
				//stdout.printf(@"Filling $i");
				_status[i]=CellState.FILLED;}
		}
		return changed;
	}
//======================================================================	
	private void record_error(string method, string errmessage, bool debug=false)
	{	//stdout.printf("record error\n");
		if (debug)
		{
		StringBuilder sb =new StringBuilder("");
		sb.append(":  ");
		sb.append(_is_column ? "column" : "row");
		sb.append(_index.to_string());
		sb.append(" in method ");
		sb.append(method);
		sb.append("\n");
		sb.append(errmessage);
		sb.append("\nClue - ");
		for(int bl=0; bl<_nblocks; bl++) sb.append(_blocks[bl].to_string()+",");
		sb.append("\n status before:\n");
		for (int i=0; i<_ncells; i++) sb.append(((int)(_temp_status[i])).to_string());
		sb.append("\n status now:\n");
		for (int i=0; i<_ncells; i++) sb.append(((int)(_status[i])).to_string());
		sb.append("Tags:\n");
		for (int i=0; i<_ncells; i++)
		{
			sb.append(@"Cell $i ");
			for (int j=0; j<_nblocks; j++) sb.append(_tags[i,j] ? "t" :"f");
			sb.append(" : ");
			for (int j=_can_be_empty_ptr; j<_can_be_empty_ptr+2; j++) sb.append(_tags[i,j] ? "t" :"f");
			sb.append("\n");
		}
		message=	message+sb.str;
		}
		else
		{
			message=method+": "+errmessage+"\n";
			_in_error=true;
		}			
	}

//	private void log_state()
//	{	message="";
//		record_error("LOG","",true);
//		stdout.printf(message);
//	}
	//======================================================================

}
