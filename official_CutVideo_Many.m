% Read many .avi in a row, and then generate smaller .avi and .tif files
% based on them. 
%
%
%
%
%
%
%
clear
clc

path2 = 'C:\Kezhi\MyCode!!!\ManualVideos\';

% please add the folder name here
addpath(genpath([path2,'.']));

ffmpeg = 'C:\FFMPEG\bin\ffmpeg';
ffprobe = 'C:\FFMPEG\bin\ffprobe';

folder = 'copied_from_pc207-8\';
root = ['N:\Kezhi\DataSet\AllFiles\nas207-1\from_pc207-7\',folder];
% folder = 'MissingFrames_example\';
% root = ['N:\Kezhi\DataSet\',folder];

root_folder = genpath([root,'.']);

file=dir([root,'*.avi']);
num_file = size(file,1);

for nf = 1:num_file;
    % end-4 because to delete '.avi'
    name  = file(nf).name(1:end-4);
    input_file = [root,name, '.avi'];
    input_file_com = ['"' input_file '"'];
    
    %randn_start = floor(15*rand(1));
    % show the length of the video
    cmd_info = sprintf('%s -i %s -show_entries format=duration -v quiet -of csv="p=0"', ffprobe, input_file_com);
    [status,video_length] = system(cmd_info);
    video_length = str2num(video_length);
    video_min = round(video_length/60);
    %vv = 15;
    if video_min > 7
        vv = round(video_min/15*2);
    else
        vv = 1;
    end
    
    randn_num = randperm(video_min);
    randn_start = randn_num(1:vv)-1;
    start_time = randn_start*60;
    recording_time = 60;   % 60
    
    curr_root = [root,name];
    mkdir([curr_root,'_tif']);
    mkdir([curr_root,'_avi']);
    
    for nn = 1:vv;
        %% generate number of vv videos
        output_file = [curr_root,'_avi', '\',name, '(',num2str(randn_start(nn)),')','.avi'];
        output_file_com = ['"' output_file '"'];
        
        cmd_cut = sprintf('%s -i %s -ss %i -c copy -t %i %s', ffmpeg, input_file_com, start_time(nn), recording_time, output_file_com);
        system(cmd_cut);
        
        %% generate tif based on the new videos
        
        vR = videoReader(output_file);
        
        next(vR)
        ii = 1;
        img = getframe(vR);
        img_info = get(vR);
        curr_img_name = [name,'(',num2str(randn_start(nn)),').tif'];
        img = rgb2gray(img);
        imwrite(img,[curr_root,'_tif','\',curr_img_name]);
       
        pre_timeStamp = 0;
        while(next(vR))
            ii = ii + 1;
            img_info = get(vR);
            cur_timeStamp = img_info.timeStamp;
             if floor(cur_timeStamp)>floor(pre_timeStamp) && pre_timeStamp ~= 0;
                    img = rgb2gray(getframe(vR));
                    imwrite(img,[curr_root,'_tif','\',curr_img_name],'WriteMode','append');
             end
             pre_timeStamp = cur_timeStamp;
        end
           
        % free memory
        vR = close(vR);
        
    end
end



