%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RLA flow design
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function is the top level code to implement matlab-to-C++
% verification platform
% RLA has options to generate test vectors to verify the algorithm.
% This program is developed and copyright owned by Soleilware LLC
% The code is writen to build the blocks for the localization
% algorithm process and efficiency.
% --------------------------------
% Created by Qi Song on 9/18/2018
%function [status]=RLA_toplevel(list_source_flag)% RLA top level function to convert Matlab code to C++ package and run C++ test code
function [mode,status,update_match_pool] = mode_manager(interrupt,scan_freq,reflector_map,reflector_source_flag,req_update_match_pool,num_ref_pool,num_detect_pool,Reflector_map,scan_data,amp_thres,angle_delta,dist_delta,thres_dist_match,thres_dist_large)
%% -interrupt:              interrupt from GUI console to control the Lidar computing engine
%% -reflector_source_flag:  flag to define the reflector source from GUI
%% -data_source_flag:       flag to define the data source from GUI
%% -req_update_match_pool:  request to ask match pool to update to include more reflectors 
%% -Reflector_map:          load Reflector map from GUI console
%% -scan_data:              load Lidar data to module
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define simulation configuration here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Prediction_flag=0;   % enable feature to calculate the location error prediction in measurement mode
%reflector_source_flag=2;    % set the list flag to 0--read from file, 1--manually set the reflector location 2--generate 120x110 reflector array 2--generate from random location
data_source_flag=reflector_source_flag;
Table_size = 12;
map_size_x = 1000;   % map x dimension in meter
map_size_y = 1000;   % map y dimension in meter
colunm_x = 4;
row_y = Table_size/colunm_x;
if reflector_source_flag == 0 % read from file   
elseif reflector_source_flag == 2 % generate the 120 reflector matrix
    for i=1:2
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
[Reflector_map, Reflector_ID, load_ref_map_status] = load_reflector_map(reflector_map);
Reflector_map
Reflector_ID
%figure(111);plot(x_pos,'+');hold on;plot(y_pos,'o')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% -- Load the test data or scan data from Lidar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
calibration_data=0;
if data_source_flag==1; 
    fname = ['Lidar_data_example1'];
    Lidar_data = dlmread( fname, ' ', 3, 0)';
    for ii=1:length(Lidar_data)
    calibration_data(ii,1) = cos(Lidar_data(1,ii)/180*pi)*Lidar_data(2,ii);
    calibration_data(ii,2) = sin(Lidar_data(1,ii)/180*pi)*Lidar_data(2,ii);
    calibration_data(ii,3) = Lidar_data(3,ii);
    end
    scan_data = Lidar_data;
elseif data_source_flag==2;     
    fname = ['Lidar_data_example2'];
    Lidar_data = dlmread( fname, ' ', 3, 0)';
    for ii=1:length(Lidar_data)
    calibration_data(ii,1) = cos(Lidar_data(1,ii)/180*pi)*Lidar_data(2,ii);
    calibration_data(ii,2) = sin(Lidar_data(1,ii)/180*pi)*Lidar_data(2,ii);
    calibration_data(ii,3) = Lidar_data(3,ii);
    end
    ll(1:length(Reflector_map))=100;
    Reflector_Table=[Reflector_map';ll]';
    calibration_data=[calibration_data;Reflector_Table];
    Reflector_data(1,:)=atan(Reflector_Table(:,2)./Reflector_Table(:,1));
    Reflector_data(2,:)=(Reflector_Table(:,1).^2+Reflector_Table(:,2).^2).^0.5;
    Reflector_data(3,:)=100;
    scan_data = Lidar_data;
    scan_data=[scan_data';Reflector_data']';
end

%% Calibration mode
[cali_status,Lidar_init_xy] = calibration_mode(Reflector_map,Reflector_ID,calibration_data,scan_data,thres_dist_match,thres_dist_large)
if cali_status==0
    disp('Calibration successful! Proceed to measurement mode....')
elseif cali_status>0
    disp('Calibration failed, please check Lidar data!!')
    %break
end
mode='Calibration';
Lidar_trace=Lidar_init_xy;

%% Measurement mode
%-- need to read the scan data and process the data at each scan
%measurement
Loop_num=scan_freq;
theta=0;
dist=0;
for ll=1:Loop_num     % simulation loop start from here!!!
%theta=theta+randi(360)/180*pi;  % define random rotation angle
if data_source_flag==1; 
theta=theta+5/180*pi;
%dist=randi(500)/20;   % define random transition
dist=50;
elseif data_source_flag==2; 
theta=135/180*pi;
%dist=dist+20*i*rand(2,1);
dist=dist+100*i;
end

[measurement_data] = simulate_lidar_movement(theta,dist,data_source_flag,calibration_data,scan_data); 
%measurement_data(:,1)=calibration_data(:,1);
%measurement_data(:,2)=calibration_data(:,2);
size(measurement_data)
[mea_status,Lidar_update_xy] = measurement_mode(num_ref_pool,num_detect_pool,Reflector_map,Reflector_ID,measurement_data,scan_data,amp_thres,angle_delta,dist_delta,Lidar_trace,thres_dist_match,thres_dist_large)
%% 

if mea_status==0
    disp('Measurement successful! continuing.....')
    status='good';
elseif mea_status==1
    disp('Measurement error found! Please check Lidar data!!')
    status='minor error';
elseif mea_status==2
    disp('Measurement large error found! Please stop test and check Lidar data!!')
    status='major error';
elseif mea_status==3
    disp('Measurement failed!')
    status='broken';
end
Lidar_trace=[Lidar_trace;Lidar_update_xy];

figure(103)
xlabel('x(cm)')
ylabel('y(cm)')
hold on;
%plot(measurement_data(:,1),measurement_data(:,2),'+g');
% color='g';
% plot_reflector(detected_reflector,detected_ID,color)
plot(Lidar_trace(:,1),Lidar_trace(:,2),'o-k')
%pause(1)
end
mode='navigation';
update_match_pool='true';
