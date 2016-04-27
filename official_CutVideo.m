% Use system command to cut a long nn-min '.avi' videos to nn videos that have 1
% min length each in sequence. Randomly select mm videos from nn videos, and convert
% this 1 min video to a 60-frame '.tif' file, where mm = round(nn/7.5)
% 
% 
% 
% 
% 
% 
% 
clear
clc

% path to restore .m files
path = 'C:\Kezhi\MyCode!!!\ManualVideos\';

% please add the folder name here
addpath(genpath([path,'.']));

ffmpeg = 'C:\FFMPEG\bin\ffmpeg';
ffprobe = 'C:\FFMPEG\bin\ffprobe';

folder = '24-02-11\';
% change .avi file names accordingly here
root = ['N:\Kezhi\DataSet\AllFiles\nas207-1\from_pc207-7\copied_from_pc207-8\',folder];

root_folder = genpath([root,'.']);

file=dir([root,'*.avi']);
num_file = size(file,1);

for nf = 2:num_file;
    
    name  = file(nf).name(1:end-4);
    input_file = [root,name, '.avi'];
    input_file_com = ['"' input_file '"'];

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

    % set times
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
        %output_file = 'Users/ajaver/Desktop/SingleWormData/Worm_Videos/output.avi';
        output_file_com = ['"' output_file '"'];


        cmd_cut = sprintf('%s -i %s -ss %i -c copy -t %i %s', ffmpeg, input_file_com, start_time(nn), recording_time, output_file_com);
        system(cmd_cut);

        %% generate tif based on the new videos
        video = mmread(output_file);

        for kk = 1:size(video,2);
            % save first frame in tif
            if kk == 1;
                curr_img_name = [name,'(',num2str(randn_start(nn)),').tif'];
                img = rgb2gray(video.frames(kk).cdata);
                imwrite(img,[curr_root,'_tif','\',curr_img_name]);
            else
                % append other frames in tif
                subsamp_ind = mod(kk,30);
                if  subsamp_ind == 1 && kk < 1800
                    img = rgb2gray(video.frames(kk).cdata);
                    imwrite(img,[curr_root,'_tif','\',curr_img_name],'WriteMode','append');
                end
            end
        end
        % free memory
        clearvars video

    end
end

    