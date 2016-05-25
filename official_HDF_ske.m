% Input: original .hdf5 file (grey image) correspoinding to labeled files
% Output: skeleton by using segworm
% 
% 
% 

%% add path of segworm algorithms
segworm_path = 'C:\Kezhi\WormTrackingSoftware\SegWorm-master\SegWorm-master';
addpath(genpath([segworm_path,'.']));

% current path and folder
folder = 'SegTif\';
path = ['X:\Kezhi\DataSet\AllFiles\OutSource_files\All_Label\'];

root_folder = genpath([path,'.']);

% hdf5 path: most of them are in hdf5_path, some of them are in hdf5_path3
hdf5_path = 'X:\Kezhi\DataSet\AllFiles\MaskedVideos\nas207-1\';
hdf5_path3 = 'X:\Kezhi\DataSet\AllFiles\MaskedVideos\nas207-3\';

file=dir([path,'Tif\','*.tif']);
num_file = size(file,1);

% change '/' to '\' due to the difference between python and matlab
failed_files_all = strrep(fileread('stage_problems.txt'),'/','\');
% replace folder
gap_sym = '\Volumes\behavgenom_archive$';

ini_loc = strfind(failed_files_all,gap_sym);



% go through all .tif files
for nf = 1: num_file;
    
    hdf5_file =[];
    
%     % current hdf5 file name
%     hdf5_file = 'C11D2.6 (gk9)IV on food R_2011_09_02__15_28___3___2';
      tif_file = file(nf).name(1:end-4);
      if tif_file(end-1)=='-'
          tif_file = tif_file(1:end-2);
      elseif tif_file(end-2)=='-'
          tif_file = tif_file(1:end-3);    
      end
    try
        hdf5_file = subdir([hdf5_path, '*',tif_file,'.hdf5']);
    catch ME
        hdf5_file = subdir([hdf5_path3, '*',tif_file,'.hdf5']);
%          fileID = fopen('files_in_3.txt','a');
%          fprintf(fileID,'%s ',tif_file);
%          fclose(fileID);
%          continue;
    end
    if isempty(hdf5_file.name)
         fileID = fopen('files_not_found_ske.txt','a');
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
                fileID = fopen('files_frame_num_ske.txt','a');
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
        seg_skeleton = {};
        curr_img_name = [tif_file,'_segske','.mat'];
        fileWrite=[path,folder,curr_img_name];
        
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
                    seg_skeleton{slice_n} = worms{slice_n}.skeleton.pixels;
                    for nn = 1: size(seg_contour,1)
                        cur_seg_img(seg_contour(nn,1),seg_contour(nn,2)) = 1;
                    end
                    
                    cur_seg_img_cl = imclose(cur_seg_img,se);
                    cur_seg_img_fl = imfill(cur_seg_img_cl);
                    %figure, imshow(cur_seg_img_fl');
                else
                    cur_seg_img_fl = cur_seg_img;
                    seg_skeleton{slice_n} = 1;
                end
                
%                 if (ii == 1)
%                     curr_img_name = [tif_file,'_seg','.tif'];
%                     imwrite(cur_seg_img_fl',[path,folder,curr_img_name]);
%                 else
%                     imwrite(cur_seg_img_fl',[path,folder,curr_img_name],'WriteMode','append');
%                 end
                
            end
        end
        if exist(fileWrite)
            delete(fileWrite);
        end
        save(fileWrite,'seg_skeleton');
        
    end
end    
    