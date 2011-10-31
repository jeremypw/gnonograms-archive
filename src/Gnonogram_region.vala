/* Region class for Gnonograms
 * Represents one row or column of grid
 * Copyright (C) 2010-2011  Jeremy Wootten
 *
	This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
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
	private bool _debug;
	public int _index;

	private bool _completed_store;
	private bool[] _completed_blocks;
	private bool[] _completed_blocks_store;
	private bool[,] _tags;
	private bool[,] _tags_store;
	private int [,] _ranges; //format: start,length,unfilled?,complete?
	private int _ncells;
	private string _clue;
	private int _nblocks;
	private int _block_total; //total cells to be filled
	private int _block_extent; //int.minimum span of blocks, including gaps of 1 cell.
	private int _unknown;
	private int _unknown_store;
	private int _filled;
	private int _filled_store;
	private int _empty;
	private int _empty_store;
	private int _can_be_empty_ptr;
	private int _is_finished_ptr;
	private int[] _blocks;
	public My2DCellArray _grid;
	private CellState[] _status;
	private CellState[] _status_store;
	private CellState[] _temp_status;
	public string message;

	private const int MAXCYCLES=100;
	private const int FORWARDS=1;
	private const int BACKWARDS=-1;
//
//=========================================================================
	public Gnonogram_region (My2DCellArray grid)
	{
		_grid=grid;
		int maxlength=int.max(Resource.MAXSIZE,Resource.MAXSIZE);
		_status=new CellState[maxlength]; _status_store=new CellState[maxlength];
		_temp_status=new CellState[maxlength];

// in order that size of class is determined initialize all array variables to maximum possible size
// get weird memory errors otherwise.

		int maxblocks=maxlength/2+2;

		_ranges=new int[maxblocks,4+maxblocks];
		_blocks=new int[maxblocks];
		_completed_blocks=new bool[maxblocks]; _completed_blocks_store=new bool[maxblocks];
		_tags=new bool[maxlength, maxblocks+2]; _tags_store=new bool[maxlength, maxblocks+2];
		//two extra flags for "can be empty" and "is finished".

	}
//=========================================================================
	public void initialize(int index, bool iscolumn, int ncells, string clue)
	{
		_index=index; 	_is_column=iscolumn;  _ncells=ncells; _clue=clue;

		int[] tmp_blocks=Utils.block_array_from_clue(clue);
		_nblocks=tmp_blocks.length;
		_can_be_empty_ptr=_nblocks; //flag for cell that may be empty
		_is_finished_ptr=_nblocks+1; //flag for finished cell (filled or empty?)
		_block_total=0;
		for (int i=0;i<_nblocks;i++)
		{
			_blocks[i]=tmp_blocks[i];
			_block_total=_block_total+tmp_blocks[i];
		}
		_block_extent=_block_total+_nblocks-1; //minimum space needed for blocks

		initial_state();
	}
//=====================================================================
	public void initial_state()
	{
		for (int i=0;i<_nblocks;i++)
		{
			_completed_blocks[i]=false;
			_completed_blocks_store[i]=false;
		}

		for (int i=0;i<_ncells;i++)
		{	//Start with no possible owners and can be empty.
			for (int j=0; j<_nblocks; j++)
			{
				_tags[i,j]=false;_tags_store[i,j]=false;
			}
			_tags[i,_can_be_empty_ptr]=true;
			_tags[i,_is_finished_ptr]=false;
			_status[i]=CellState.UNKNOWN;
			_temp_status[i]=CellState.UNKNOWN;
		}

		_in_error=false;
		_completed=(_ncells==1); //allows debugging of single row
		if (_completed) return;
		_unknown=99;
		_filled=99;
		_empty=-1;

		get_status();

		if (_blocks[0]==0) //trivial solution - complete now
		{
			for (int i=0;i<_ncells;i++)
			{
				for (int j=0; j<_nblocks; j++) _tags[i,j]=false;
				//Start with no possible owners and empty.
				_tags[i,_can_be_empty_ptr]=false;
				_tags[i,_is_finished_ptr]=true;
				_status[i]=CellState.EMPTY;
				_temp_status[i]=CellState.EMPTY;
			}
			_completed=true;
		}
		else	initial_fix();

		tags_to_status();
		put_status();
	}
//======================================================================
	private void initial_fix()
	{//stdout.printf(@"$(this) initial_fix\n");
			int freedom=_ncells-_block_extent;
			int start=0;
			int length=0;

			for (int i=0; i<_nblocks; i++)
			{
				length=_blocks[i]+freedom;
				for (int j=start; j<start+length; j++) _tags[j,i]=true;
				if (freedom<_blocks[i])
				{
					set_range_owner(i,start+freedom,_blocks[i]-freedom,true,false);
				}
				start=start+_blocks[i]+1; //leave a gap between blocks
			}

			if (freedom==0) _completed=true;
	}
//======================================================================
	public bool solve(bool debug=false)
	{
		/**cycles through ploys until no further changes can be made
		ignore single cell regions for testing purposes ...
		* */
		//stdout.printf(@"Region $_index $_is_column Solve debug $debug _debug $_debug\n");
		message="";
		_debug=debug;
		if (_completed) return false;

		bool made_changes=false;
		get_status();
		bool still_changing=totals_changed(); //also detects whether completed and if so calls check_nblocks.

		if (_completed || _in_error||!still_changing) return false;

		int count=0;
		while (!_completed && count<MAXCYCLES) //count guards against infinite loops
		{
			count++;
			still_changing=full_fix();
			if (_in_error) break;

			tags_to_status();
			if (totals_changed())
			{
				if(_in_error) break;
				else made_changes=true;
			}
			else break;
		}
		if ((made_changes && !_in_error)||debug) put_status(debug);
		if (count==MAXCYCLES) stdout.printf("Excessive looping in region %d\n",_index);

		return made_changes;
	}
//======================================================================

	private bool full_fix()
	{	//if (_debug) stdout.printf("\n\nfull_fix\n");
		//stdout.printf("Capped range audit\n");
		if (capped_range_audit()||_in_error||tags_to_status()) {
			//stdout.printf("Capped range audit made changes\n");
			return true;}
		//stdout.printf("Possibilities audit\n");
		if (possibilities_audit()||_in_error||tags_to_status()) {
			//stdout.printf("possibilities audit made change\n");
			return true;}
		//stdout.printf("Only_possibility\n");
		if (only_possibility()||_in_error||tags_to_status()) {
			//stdout.printf("only possibility made change\n");
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
		//stdout.printf("Fill_gaps\n"); //Redundant?
		if (fill_gaps()||_in_error||tags_to_status()) {
			//stdout.printf("fill gaps made change\n");
			return true;}
		//stdout.printf("Free cell audit\n");
		if (free_cell_audit()||_in_error||tags_to_status()) {
			//stdout.printf("free cell audit audit made change\n");
			return true;}
		//stdout.printf("Fix blocks in ranges\n");
		if (fix_blocks_in_ranges()||_in_error||tags_to_status()) {
			//stdout.printf("Fix blocks in ranges made change\n");
			return true;}

		return false;
	}

//======================================================================
	private bool filled_subregion_audit() {
//find a range of filled cells not completed and see if can be associated
// with a unique block.
	//stdout.printf("Filled subregions audit\n");
		bool changed=false, start_capped, end_capped;
		int idx=0;
		int length;

		while (idx<_ncells)
		{//find a filled sub-region
			start_capped=false; end_capped=false;
			if (skip_while_not_status(CellState.FILLED,ref idx, _ncells, 1))
			{
				//idx points to first filled cell or returns false
				if (_tags[idx,_is_finished_ptr]) {idx++;continue;}//ignore if completed already
				if(idx==0 || _status[idx-1]==CellState.EMPTY) start_capped=true;
				length=count_next_state(CellState.FILLED, idx);//idx not changed
				int lastcell=idx+length-1;
				if (lastcell==_ncells-1 || _status[lastcell+1]==CellState.EMPTY) end_capped=true;

				//is this region capped?
				if (start_capped && end_capped)
				{// assigned block must fit exactly
					assign_and_cap_range(idx,length);
					changed=true;
				}
				else
				{
					int largest=find_largest_possible_in_cell(idx);

					if (largest==length)
					{//there is **at least one** largest block that fits exactly.
					// this region must therefore be complete
						assign_and_cap_range(idx,length);
						changed=true;
					}
					else
					{//remove blocks that are smaller than length from this region and one cell either side.
					//For the two cells adjacent to the region, add one to the minimum length

						//stdout.printf(@"Removing too small blocks idx $idx lengt $length \n");
						int start = idx==0 ? idx : idx-1;
						int end = (idx+length ==_ncells) ? idx+length-1 : idx+length;
						for (int bl=0;bl<_nblocks;bl++){
							for(int i=start;i<=end;i++){
								if (_tags[i,bl] && _blocks[bl]<length) _tags[i,bl]=false;
							}
						}

//						if(start>0){
//							for (int bl=0;bl<_nblocks;bl++){
//								if (_tags[start,bl] && _blocks[bl]<length+1) _tags[start,bl]=false;
//							}
//						}
//						if(end<_ncells){
//							for (int bl=0;bl<_nblocks;bl++){
//								if (_tags[end,bl] && _blocks[bl]<length+1) _tags[end,bl]=false;
//							}
//						}

						if (start_capped || end_capped)
						//TODO look for empty cells nearer than difference between smallest and length.
						{
							int smallest=find_smallest_possible_in_cell(idx);

							if (smallest>length)
							{//extend filled cells
								int count=smallest-length;
								//int start;
								int direction;
								if(end_capped) {start=idx-1;direction=BACKWARDS;}
								else {start=idx+length;direction=FORWARDS;}

								for(int i=0;i<count;i++)
								{
									_tags[start,_can_be_empty_ptr]=false;
									start+=direction;
								}
								changed=true;
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
					changed=set_range_owner(owner,cell1,idx-cell1+1,true,false)||changed;
				}
				idx--;//TEST
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
			//this range not proved exclusive to this block;
				changed=fix_block_in_range(i,start,length)||changed;
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
		int count=0;
		int[] max_blocks=new int[_nblocks];
		int first=_nblocks;
		int last=0;
		int end=start+length-1;  //TEST

		for (int i=0;i<_nblocks;i++)
		{
			if (_completed_blocks[i]) continue;
			if (_blocks[i]!=length) continue;
			if (!_tags[start,i]||!_tags[end,i]) continue;

			max_blocks[count]=i;
			count++;

			if (i<first) first=i;
			if (i>last) last=i;
		}

		if(count==0) return; //not necessarily an error
		if (count==1)
		{//unique owner
			set_block_complete_and_cap(max_blocks[0],start);
		}
		else
		{//ambiguous owner
			//delete out of sequence blocks before end of range
			for (int i=last+1;i<_nblocks;i++) //TEST
			{
				remove_block_from_cell_to_end(i,start+length-1,-1);
			}
			//delete out of sequence blocks after start of range
			for (int i=0;i<first;i++) //TEST
			{
				remove_block_from_cell_to_end(i,start,1);
			}
			//remove as possible owner blocks between first and last that are wrong length
			for (int i=first+1;i<last;i++)
			{
				if (_blocks[i]==length) continue;
				remove_block_from_range(i,start,length,1);
			}

			//for each possible mark as possible owner of subregion (not exclusive)
			for (int i=0;i<count;i++)
			{
				set_range_owner(max_blocks[i],start,length,false, false);
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
		int limit; //first out of range value of idx depending on direction
		bool changed=false; //tags changed?
		bool dir=(direction==FORWARDS);

		if (dir)
		{
			idx=0; blocknum=0; limit=_ncells;
		}
		else
		{
			idx=_ncells-1; blocknum=_nblocks-1; limit=-1;
		}

		if (!find_edge(ref idx,ref blocknum,limit,direction))	return false;

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
						set_cell_owner(idx,blocknum,true,false);
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
					set_cell_owner(idx,blocknum,true,false);
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
		bool dir=(direction==FORWARDS);
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
		return found;
	}
//======================================================================
  private bool fix_blocks_in_ranges()
	{
		int empty=count_cell_state(CellState.EMPTY);
		if (_empty>=empty) return false; // no change in ranges since last time
		int[] blocks=blocks_available();
		int bl=blocks.length;
		int[,] block_start = new int[bl,2]; //range number and offset of earliest start point
		int[,] block_end = new int[bl,2]; //range number and offset of latest end point

		int nranges=count_available_ranges(false);//update _ranges with currently available ranges (can contain only unknown cells)
		if(nranges<2) return false;
		//find earliest start point of each block (assuming ranges all unknown cells)
		int rng=0, offset=0, length=0; //start at beginning of first available range
		for (int b=0; b<bl; b++) //for each available block
		{	length=_blocks[blocks[b]]; //get its length
			if (_ranges[rng,1]<(length+offset)) //cannot fit in current range
			{
				rng++; offset=0;//skip to start of next range
				while (rng<nranges && _ranges[rng,1]<length){
				rng++;} //keep skipping if too small

				if (rng>=nranges)
				{	//record_error("Fix blocks in ranges", "Dont fit",false);
					return false;
				}
			}
			block_start[b,0]=rng; //set start range number
			block_start[b,1]= offset; //and start point
			offset+=(length+1); //move offset allowing for one cell gap between blocks
		}
		//carry out same process in reverse to get latest end points
		rng=nranges-1; offset=0; //start at end of last range NB offset now counts from end
		for (int b=bl-1; b>=0; b--) //start at last block
		{	length=_blocks[blocks[b]]; //get length
			if (_ranges[rng,1]<(length+offset))//doesn't fit
			{
				rng--; offset=0; //skip to end of previous block
				while (rng>=0 && _ranges[rng,1]<length) rng--; //keep skipping if too small

				if (rng<0)
				{
					//record_error("Reverse Fix blocks in ranges", "Dont fit",false);
					return false;
				}
			}
			block_end[b,0]=rng; //set end range number
			block_end[b,1]= _ranges[rng,1]-offset;	//and end point
			//NB end point is index of cell AFTER last possible cell so that
			//subtracting start from end gives length of range.
			offset+=(length+1); //shift offset allowing for one cell gap
		}

		for (int b=0; b<bl; b++) //for each available block
		{
			rng=block_start[b,0];offset=block_start[b,1];
			int start=_ranges[rng,0];
			if (rng==block_end[b,0]) //if starts and ends in same range
			{
				length=block_end[b,1]-block_start[b,1]; //'length' now used for total length of possible range for this block
				fix_block_in_range(blocks[b],start+offset,length);
			}
			//remove block from outside possible range
			if(offset>1)remove_block_from_range(blocks[b],start,offset-1);
			for (int r=0; r<block_start[b,0];r++) //ranges before possible
			{
				remove_block_from_range(blocks[b],_ranges[r,0],_ranges[r,1]);
			}
			rng=block_end[b,0];
			start=_ranges[rng,0]+block_end[b,1];
			length=_ranges[rng,1]-block_end[b,1];
			if(length>0)remove_block_from_range(blocks[b],start,length);
			for (int r=nranges-1; r>block_end[b,0]; r--) //ranges after possible
			{
				remove_block_from_range(blocks[b],_ranges[r,0],_ranges[r,1]);
			}
		}
		return true;
	}
//======================================================================
	private bool capped_range_audit()
	{//only changes tags so returns false
		//if(_debug) stdout.printf("fix blocks in ranges\n");
		int start=0, length=0, idx=0;
		int nranges=count_capped_ranges();
		if (nranges==0) return false;
		for (int rng=0; rng<nranges; rng++)
		{
			start=_ranges[rng,0];
			length=_ranges[rng,1];
			for (idx=start;idx<start+length;idx++)
			{	int count=0;
				for(int b=0;b<_nblocks;b++)
				{
					if(_tags[idx,b])
					{count++;
						if(_blocks[b]!=length)
						{
							_tags[idx,b]=false;
							count--;
						}
					}
				}
				if (count==0)
				{
					record_error("capped range audit","filled cell with no owners",false);
					return false;
				}
			}
		}
		return false;
	}
//======================================================================
// END OF PLOYS
// HELPER FUNCTIONS FOLLOW
//======================================================================
	private bool skip_while_not_status(CellState cs, ref int idx, int limit, int direction)
	{
	// increments/decrements idx until cell of required state
	// or end of range found.
	//returns true if cell with status cs was found
	//	bool dir=(direction>0);
	if (direction==FORWARDS && idx>=limit)  return false;
	else if (direction==BACKWARDS && idx<=limit) return false;

		for (int i=idx; i!=limit;i+=direction)
		{
			if (_status[i]==cs)
			{
				idx=i;
				return true;
			}
		}
		return false;
	}
//======================================================================
	private int count_next_state(CellState cs, int idx, bool forwards=true)
	{
	// count how may consecutive cells of state cs starting at given index idx (inclusive of starting cell)
		int count=0;
		if (forwards && idx>=0)
		{
			while (idx<_ncells && _status[idx]==cs) {
				count++;
				idx++;
			}
		}
		else if (!forwards && idx<_ncells)
		{
			while (idx>=0 && _status[idx]==cs) {
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
			while (idx<_ncells && _tags[idx,owner] &&
					!_tags[idx,_is_finished_ptr]) {
				count++;
				idx++;
			}
		}
		else {_in_error=true;message="count_next_owner idx negative\n";}

		return count;
	}
//===================================================================
	private int count_available_ranges(bool not_empty) {
	// determine location of ranges of unknown or unfinished filled cells
	// and store in _ranges[,]
	// _ranges[ ,2] indicates number of filled,
	// _ranges[ ,3] indicates number of unknown
		int range=0, start=0, length=0, idx=0;
		//skip to start of first range;
		while (idx<_ncells && _tags[idx,_is_finished_ptr]) idx++;

		while (idx<_ncells)
		{
			length=0;
			start=idx;
			_ranges[range,0]=start;
			_ranges[range,2]=0;
			_ranges[range,3]=0;

			while (idx<_ncells && !_tags[idx,_is_finished_ptr])
			{
				if (!_tags[idx,_can_be_empty_ptr]) _ranges[range,2]++; //FILLED
				else _ranges[range,3]++; //UNKNOWN

				idx++; length++;
			}

				if(not_empty && _ranges[range,2]==0) {} //dont include completely empty ranges
				else {_ranges[range,1]=length; range++;}

			//skip to beginning of next range
			while (idx<_ncells && _tags[idx,_is_finished_ptr]) idx++;
		}
		return range; //number of ranges - not last index!
	}
//======================================================================
	private bool check_nblocks()
	{//only called when region is completed. Checks whether number of blocks is correct
		int count=0, idx=0;
		while (idx<_ncells)
		{
			while (idx<_ncells && _status[idx]==CellState.EMPTY) idx++;
			if (idx<_ncells) count++;
			else break;
			while (idx<_ncells && _status[idx]!=CellState.EMPTY) idx++;
		}
		if (count!=_nblocks)
		{
			record_error("Check n_blocks",@"Wrong number of blocks found $count should be $_nblocks");
			return false;
		}
		else return true;
	}
//======================================================================
	private int count_capped_ranges() {
	// determine location of capped ranges of filled cells (not marked complete) and store in _ranges[,]

		int range=0, start=0, length=0, idx=0;
		while (_status[idx]!=CellState.FILLED && idx<_ncells) idx++; //skip to beginning of first range
		while (idx<_ncells)
		{
			length=0;
			start=idx;
			_ranges[range,0]=start;
			_ranges[range,2]=0; //not used
			_ranges[range,3]=0; //not used

			while (_status[idx]==CellState.FILLED && idx<_ncells)
			{
				idx++; length++;
			}

			if ((start==0||_status[start-1]==CellState.EMPTY) && (idx==_ncells||_status[idx]==CellState.EMPTY)) //capped
			{
				_ranges[range,1]=length;
				range++;
			}

			while (_status[idx]!=CellState.FILLED && idx<_ncells) idx++; //skip to beginning of next range
		}
		return range;
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
	private bool fix_block_in_range(int block, int start, int length)//,bool exclusive)
	{
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
				else set_range_owner(block,start+freedom,block_length-freedom,true,false);
			}
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
	//	if (_completed_blocks[i]) continue;// ignore complete block
			if (!_tags[cell,i]) continue; // not possible
			if (_blocks[i]<=max_size) continue; // not largest
			max_size=_blocks[i]; //update largest
		}
		return max_size;
	}
//==============================================================
	private int find_smallest_possible_in_cell(int cell)
	{
	// find the largest incomplete block possible for given cell
		int min_size=9999;
		for (int i=0;i<_nblocks;i++)
		{
			if (!_tags[cell,i]) continue; // not possible
			if (_blocks[i]>=min_size) continue; // not largest
			min_size=_blocks[i]; //update largest
		}
		if (min_size==9999)
		{
			_in_error=true;
			message="No blocks possible in filled cell";
			return 0;
		}
		return min_size;
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
			_in_error=true; message=@"remove block from range - invalid data- start $start block $block length $length\n";
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
		set_range_owner(block,start,length,true,false);

		if (start>0) set_cell_empty(start-1);
		if (start+length<_ncells) set_cell_empty(start+length);

		for (int cell=start; cell<start+length; cell++) set_cell_complete(cell);
		//taking into account minimum distance between blocks.
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
	private bool set_range_owner(int owner, int start, int length, bool exclusive, bool can_be_empty)
	{
		//if (_debug) stdout.printf(@"set range owner start=$start length=$length exclusive $exclusive, can be empty $can_be_empty\n");
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

				if (block_length<length && !can_be_empty)

				{
					_in_error=true; message="set_range_owner - contradiction - range too big for owner\n"; return false;
				}

				int bstart=int.min(start-1,start+length-block_length);

				if(bstart>=0)remove_block_from_cell_to_end(owner,bstart-1,-1);

				int bend=int.max(start+length,start+block_length);

				if (bend<_ncells)remove_block_from_cell_to_end(owner,bend);

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
	private bool set_cell_owner(int cell, int owner, bool exclusive, bool can_be_empty)
	{ //if (_debug) stdout.printf(@"set cell owner cell=$cell owner=$owner exclusive=$exclusive, can be empty $can_be_empty\n");
	//exclusive - cant be any other block here
	//can be empty - self evident
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
				for (int i=0; i<_nblocks; i++) _tags[cell,i]=false;
			}
			if(!can_be_empty)
			{
				_status[cell]=CellState.FILLED; changed=true;
				_tags[cell,_can_be_empty_ptr]=false;
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
		return (start<0||start>=_ncells||length<0||start+length>_ncells||block<0||block>=_nblocks);
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
//		if (_cycles==0) return true;
//forces fullfix even if initial fix does not make changes on first visit
// and cells have been set by intersecting ranges.

		bool changed=false;
		int unknown=count_cell_state(CellState.UNKNOWN);
		int filled=count_cell_state(CellState.FILLED);
		int completed=count_cell_state(CellState.COMPLETED);

		if (_unknown!=unknown || _filled!=filled)
		{
			changed=true;
			_unknown=unknown;
			_filled=filled;

			if (filled+completed>_block_total) record_error("totals changed","too many filled cells");
			else if (unknown==0)
			{
				 _completed=true;
				 if (filled+completed<_block_total) record_error("totals changed",@"too few filled cells - $_filled");
				 else check_nblocks();
			}
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
					_status[i]=CellState.UNKNOWN;
					break;

				case CellState.EMPTY :
					if (!_tags[i,_can_be_empty_ptr])
					{
						record_error("get_status", @"cell $i cannot be empty");
					}
					else	_status[i]=CellState.EMPTY;

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
					}

					break;

				default : break;
			}
			status_to_tags();
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
	//duplicates function of get_status??
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
	{//stdout.printf("tags to status\n");
		bool changed=false;
		for (int i=0;i<_ncells; i++)
		{
			// skip cells not unknown or with more than one possibility (including empty)
			if (_status[i]!=CellState.UNKNOWN) continue;
			if (!_tags[i,_can_be_empty_ptr])
			{
				_status[i]=CellState.FILLED;
				changed=true;
				continue;
			}
			if(count_owners_and_empty(i)>1) continue;
			changed=true;
			//Either the 'can be empty' flag is set and there are no owners (ie cell is empty) or there is one owner.
			if (_tags[i,_can_be_empty_ptr]){
				_status[i]=CellState.EMPTY; _tags[i,_is_finished_ptr]=true;}
			else {
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
		sb.append("\nTags:\n");
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
	public void save_state()
	{
		for (int i=0;i<_ncells;i++)
		{
			_status_store[i]=_status[i];
			for (int j=0; j<_nblocks+2; j++) _tags_store[i,j]=_tags[i,j];
		}
		for (int j=0; j<_nblocks; j++) _completed_blocks_store[j]=_completed_blocks[j];

		_completed_store=_completed;
		_filled_store=_filled;
		_unknown_store=_unknown;
		_empty_store=_empty;
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
		_filled=_filled_store;
		_unknown=_unknown_store;
		_empty=_empty_store;

		_in_error=false; message="";
	}
//======================================================================
	public int value_as_permute_region()
	{
		if (_completed) return 0;
		int navailable_ranges=count_available_ranges(false);
		if (navailable_ranges!=1) return 0;  //useless as permute region

		int block_extent=0,count=0,largest=0;
		for(int b=0;b<_nblocks;b++)
		{
			if(!_completed_blocks[b]) {
				block_extent+=_blocks[b];
				count++;
				largest=int.max(largest,_blocks[b]);
			}
		}

		int pvalue = (largest-1)*block_extent; //block length 1 useless
		if (count==1) pvalue=pvalue*2;
		return pvalue;
	}
//======================================================================
	public Gnonogram_permutor? get_permutor(out int start)
	{
		string clue=""; start=0;
		int[] ablocks=blocks_available();
		for(int b=0;b<ablocks.length;b++)
		{
			clue=clue+_blocks[ablocks[b]].to_string()+",";
		}

		//Find available range (must be only one)
		if (count_available_ranges(false)!=1) {stdout.printf("ERROR in get permutator - more than one range\n"); return null;}

		start=_ranges[0,0];
		var p=new Gnonogram_permutor(_ranges[0,1],clue);
		//stdout.printf(@"Permutator from $(this) start $start length $(_ranges[0,1]) blocks used $(clue)\n");
		return p;
	}

	public string to_string()
	{
		string colrow;
		if (_is_column) colrow="Column";
		else colrow="Row";
		return @"$colrow $_index ($_clue)";
	}
//======================================================================

//	private void log_state()
//	{	message="";
//		record_error("LOG","",true);
//		stdout.printf(message);
//	}
//======================================================================

}
