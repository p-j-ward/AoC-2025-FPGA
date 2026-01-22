The following is my attempt at the Advent of FPGA 2025 challenge, I've implemented a solution to day4 (specifically part 2) in VHDL. I chose to start with day 4 as the structure of the problem lends itself well to a parallel solution.

Starting out I had the idea of convolution in mind, as calculation of accessible rolls looks a lot like sliding a 2D kernel across the data. I stared out with the bit_convolution_2d component, which carries out this 'bit convolution' in a parallel fashion. By bit convolution, I refer to sliding an arbitrary function from a 3x3 grid of bits -> a single bit over the 2D data; as the function can be arbitrary - and in the case of this problem is in fact non-linear - bit convolution is more something analogous to convolution. The bit_convolution_2d component has a parallel input bus (which is one dimension of the data), which it ingests one cycle at a time into a 3-deep pipeline, from which is calculates the output, thus we get our second dimension from time. An important point to note about bit_convolution_2d is its output bus is 2 bits narrower than its input, due to the sides.

The output of bit_convolution_2d corresponds to the accesible rolls, for a given input. The next level up the heirarchy is conv_count_update_step, which is a block which 1) applies the bit convolution, 2) counts the number of bits set on the result of the convolution, which gives our accessible roll count for that step, and 3) performs the update, by passing along the input data (albeit 2 bits narrower) with the accesible rolls zeroed. The 'step' in the name refers to the fact that this component is intended to be chained in a pipeline, wherein each stage in the pipeline will perform one step of iteration. The next level up the heirarchy, conv_count_update_pipeline, structurally generates this pipeline.

If the input line width and (max possible) number of steps of iteration is known ahead of time then conv_count_update_pipeline is already good enough to get the part 2 solution. If we call MAX_ITER_STEPS the largest number of iterations we need, then a pipeline MAX_ITER_STEPS deep, combined with zero padding the input bus with MAX_ITER_STEPS zeros either side will give the solution. The test_conv_count_update_pipeline does this for the example solution (of 10 steps of iteration).

For arbitrary inputs aoc25_day4_toplevel is the scalable solution. The IO to the outside world consists of a memory interface to a ram which should be initialised with the problem data, as well as Num_lines_in/Num_cols_in which gives the problem dimensions, and finally control signals Ready_out/Start_in for setting off the computation and a Done_out pulse which is asserted when Count_out is updated with the solution.

Recall that the pipeline sweeps down the input, to generalise this to larger inputs we now perform multiple passes down, where each pass represents sweeping down one column and in doing so performing PIPELINE_DEPTH steps of the cellular automata updates. We repeat this process until we reach a fixed point, at which point the count (which has been accumulating througout) gives the solution. The issue I faced when implementing these multiple sweeps down/across was that of the overlap between columns at the edges. Due to the nature of the computation, bit_convolution_2d's output is two bits narrower than its input, and the pipeline's output is 2*PIPELINE_DEPTH bits narrower (the pipeline data looking like an inverted pyramid). The fact that the pipeline output is a different width to its input makes naively writing back intermediate results problematic. I wanted to have a simple word addressed memory interface to be realistic to hardware (thus I ruled out a bit-enable signal for writes), but also keeping track of these overlap bits to collate a full word to write back also seemed inelegant.

The solution I settled on was as follows: the depth of the pipeline is set to to the word length of the memory, which allows us to have a pipline with input width of three words and output width of a single word. I call the three words left, centre, and right. The left and centre words come from two local caches (which were updated on previous passes down), and the right word is read from the external memory. As well as feeding the pipeline, the right word is also written to the left cache. Physically, we have two caches A and B, whose role as left and right changes each cycle with muxes controlled by the write_to_cache_a_not_b flag. The logic is described by the following comment above the control_proc:

```
-- We make passes going down the file, line by line, after each pass we can
-- move one column across, the sequence for one pass down is as follows:
--   1. Initialse by zeroing cache a (right) and loading first column (hence
--      column 1) of input data into cache b (centre).
--   2. First pass down: input to pipeline is \[cache a, cache b, memory]
--      where memory is the external memory (data column 2 in this case).
--      Simultaneously we load memory into cache a. The output of the
--      pipeline for this step will be written back to memory column 1.
--   3. Second pass down: input to pipeline is \[cache b, cache a, memory],
--      recall cache b contains column 1, cache a contains column 2, and the
--      pipeline output will be written back to column 2. Simultaneously we
--      load memory into cache b.
--   4. Repeat steps 2 and 3, moving one column across the input with each
--      pass down, and ping-ponging the caches.
```

# How to Run

With a terminal in the day4 folder, run the run_testbenches.sh script. This produces the following gtkwave waveform files in the day4 folder:
>test_bit_convolution_2d_result.ghw
>
>test_conv_count_update_step_result.ghw
>
>test_conv_count_update_pipeline_result.ghw
>
>test_aoc25_day4_toplevel_result.ghw

These files can also be be found in the repo folder, created with GHDL 4.1.0 running on macOS Ventura.


# Simulation Waveforms

The following result of the testbench for aoc25_day4_toplevel, running on the example input. The answer is output on the Count_out signal, which is 43, as per the example.

<img width="1250" height="287" alt="day4_tb_view_waveform" src="https://github.com/user-attachments/assets/db718c48-2ee9-4f51-93ee-e1d201316002" />

Here is a more detailed view, showing most of the internal signals inside aoc25_day4_toplevel:

<img width="1250" height="739" alt="day4_tb_detail_view_waveform" src="https://github.com/user-attachments/assets/8b719313-38e0-48b1-8720-d6d0ee696dee" />
