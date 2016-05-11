%% add path of segworm algorithms
segworm_path = 'C:\Kezhi\WormTrackingSoftware\SegWorm-master\SegWorm-master';
addpath(genpath([segworm_path,'.']));

% current path and folder
folder = 'SegTif\';
path = ['N:\Kezhi\DataSet\AllFiles\OutSource_files\All_Label\'];

root_folder = genpath([path,'.']);

hdf5_path = 'N:\Kezhi\DataSet\AllFiles\MaskedVideos\nas207-1\';
hdf5_path3 = 'N:\Kezhi\DataSet\AllFiles\MaskedVideos\nas207-3\pc207-8-Laura\';

file=dir([path,'Tif\','*.tif']);
num_file = size(file,1);

%% read from text file
% change '/' to '\' due to the difference between python and matlab
failed_files_all = fileread('files_in_3.txt');
% replace folder
gap_sym1 = '(';
gap_sym2 = ')';

ini_loc1 = strfind(failed_files_all,gap_sym1);
ini_loc2 = strfind(failed_files_all,gap_sym2);
ini_loc =[];

ind_ii = 1;
for ii = 1:numel(ini_loc1)
    if ini_loc2(ii)-ini_loc1(ii)<=3
        ini_loc(ind_ii) = ini_loc2(ii);
        ind_ii = ind_ii+1;
    end
end

file_name = {};
file_name = [file_name;failed_files_all(1:ini_loc(1))];
% restore file names to independent cell
for ii = 2:numel(ini_loc);
    file_name = [file_name;failed_files_all(ini_loc(ii-1)+2:ini_loc(ii))];
end
%file_name = [file_name;failed_files_all(ini_loc(numel(ini_loc)):end)];



% go through all .tif files
for nf = 1: numel(ini_loc) %num_file;
    
    hdf5_file =[];
    
%     % current hdf5 file name
%     hdf5_file = 'C11D2.6 (gk9)IV on food R_2011_09_02__15_28___3___2';
      %tif_file = file(nf).name(1:end-4);
      
      tif_file = strtrim(file_name{nf});
%       if tif_file(end-1)=='-'
%           tif_file = tif_file(1:end-2);
%       elseif tif_file(end-2)=='-'
%           tif_file = tif_file(1:end-3);    
%       end
     try
        hdf5_file = subdir([hdf5_path3, '*',tif_file,'.hdf5']);
    catch ME
         fileID = fopen('files_in_3_not3.txt','a');
         fprintf(fileID,'%s ',tif_file);
         fclose(fileID);
         continue;
    end
    if isempty(hdf5_file.name)
         fileID = fopen('files_not_found_in_3.txt','a');
         fprintf(fileID,'%s ',tif_file);
         fclose(fileID);
    else
        mask_info = h5info(hdf5_file.name, '/mask');
        frame_size = mask_info.Dataspace.Size(1:2);
        frame_total = mask_info.Dataspace.Size(3);
        time_start = h5read(hdf5_file.name,'/time_start'); % start from 0
        time_pos = h5read(hdf5_file.name,'/vid_time_pos');        
        
               normalize_val = 1000;
        
        if frame_total~=length(time_pos)
                sprintf('frame number is not equal to number of time stamps');
                fileID = fopen('files_frame_num_in_3.txt','a');
                fprintf(fileID,'%s ',tif_file);
                fclose(fileID);
        end
        
        cur_mask = h5read(hdf5_file.name,'/mask');
        
        % if the mask is normalized
        normalized = 1;
        % need dilute or erode
        verbose = 0;
        % close opration to the contour with disk to make sure it is a
        % close area
        se = strel('disk',3);
        % index of slice
        slice_n = 0;
        pre_timeStamp = 0;
        cur_timeStamp = 0;
        
        for ii = 1:frame_total;
            % print current ii
            if mod(ii,100)==0
                sprintf([num2str(ii),'/',num2str(frame_total),';',num2str(nf),'/',num2str(num_file)])
            end
            
            pre_timeStamp = cur_timeStamp;
            cur_timeStamp = time_pos(ii);
            if (ii == 1) |( floor(cur_timeStamp)>floor(pre_timeStamp))
                slice_n = slice_n +1;
                
                worms{slice_n} = segWorm(cur_mask(:,:,ii), slice_n, normalized, verbose);
                
                cur_seg_img = zeros(frame_size);
                if ~isempty(worms{slice_n})
                    seg_contour = worms{slice_n}.contour.pixels;
                    
                    for nn = 1: size(seg_contour,1)
                        cur_seg_img(seg_contour(nn,1),seg_contour(nn,2)) = 1;
                    end
                    
                    cur_seg_img_cl = imclose(cur_seg_img,se);
                    cur_seg_img_fl = imfill(cur_seg_img_cl);
                    %figure, imshow(cur_seg_img_fl');
                else
                    cur_seg_img_fl = cur_seg_img;
                end
                
                if (ii == 1)
                    curr_img_name = [tif_file,'_seg','.tif'];
                    imwrite(cur_seg_img_fl',[path,folder,curr_img_name]);
                else
                    imwrite(cur_seg_img_fl',[path,folder,curr_img_name],'WriteMode','append');
                end
                
            end
        end
        
        
    end
end    
    