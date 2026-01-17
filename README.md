The following is my attempt at the Advent of FPGA 2025 challenge, I've implemented a solution to day4 (specifically part 2) in VHDL. I chose to start with day 4 as the structure of the problem lends itself well to a parallel solution.

Starting out I had the idea of convolution in mind, as calculation of accessible rolls looks a lot like sliding a 2D kernel across the data. I stared out with the bit_convolution_2d component, which carries out this 'bit convolution' in a parallel fashion. By bit convolution, I refer to sliding an arbitrary function from a 3x3 grid of bits -> a single bit over the 2D data; as the function can be arbitrary - and in the case of this problem is in fact non-linear - bit convolution is more something analogous to convolution. The bit_convolution_2d component has a parallel input bus (which is one dimension of the data), which it ingests one cycle at a time into a 3-deep pipeline, from which is calculates the output, thus we get our second dimension from time. An important point to note about bit_convolution_2d is its output bus is 2 bits narrower than its input, due to the sides.

The output of bit_convolution_2d corresponds to the accesible rolls, for a given input. The next level up the heirarchy is conv_count_update_step, which is a block which 1) applies the bit convolution, 2) counts the number of bits set on the result of the convolution, which gives our accessible roll count for that step, and 3) performs the update, by passing along the input data (albeit 2 bits narrower) with the accesible rolls zeroed. The 'step' in the name refers to the fact that this component is intended to be chained in a pipeline, wherein each stage in the pipeline will perform one step of iteration. The next level up the heirarchy, conv_count_update_pipeline, structurally generates this pipeline.

If the input line width and (max possible) number of steps of iteration is known ahead of time then conv_count_update_pipeline is already good enough to get the part 2 solution. If we call MAX_ITER_STEPS the largest number of iterations we need, then a pipeline MAX_ITER_STEPS deep, combined with zero padding the input bus with MAX_ITER_STEPS zeros either side will give the solution. The test_conv_count_update_pipeline does this for the example solution (of 10 steps of iteration).

For unbounded inputs aoc25_day4_toplevel is the scalable solution.

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
