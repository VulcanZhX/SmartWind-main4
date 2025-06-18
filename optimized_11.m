clc
clear all
close all

optimization_result_cell=cell(1,8);

load('swi_0_8_final.mat')
optimization_result_cell{1,1}=swi;

load('swi_45_8_final.mat')
optimization_result_cell{1,2}=swi;

load('swi_90_8_final.mat')
optimization_result_cell{1,3}=swi;

load('swi_135_8_final.mat')
optimization_result_cell{1,4}=swi;

load('swi_225_8.mat')
optimization_result_cell{1,6}=swi;

load('swi_270_8_final.mat')
optimization_result_cell{1,7}=swi;








