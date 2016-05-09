%% add path of segworm algorithms
segworm_path = 'C:\Kezhi\WormTrackingSoftware\SegWorm-master\SegWorm-master';
addpath(genpath([segworm_path,'.']));

% current path and folder
folder = 'pc207-14-Laura\';
path = ['N:\Kezhi\DataSet\AllFiles\MaskedVideos\nas207-3\',folder];

root_folder = genpath([path,'.']);

% file=dir([path,'*.hdf5']);
% num_file = size(file,1);

% go through all .hdf5 files
for nf = 1: 1; % num_file;
    
    % current hdf5 file name
    hdf5_file = 'C11D2.6 (gk9)IV on food R_2011_09_02__15_28___3___2';
    
    %     hdf5_file = file(nf).name(1:end-5);
    
    hdf5_path = [path,hdf5_file,'.hdf5'];
    sub_folder = [path,hdf5_file,'_tif\'];
    
    sub_file=dir([sub_folder,'*.hdf5']);
    sub_num_file = size(sub_file,1);
    
    % go through all sub folders
    for sub_no = 1:1; % sub_num_file
        sub_hdf5_file = sub_file(nf).name(1:end-5);
        sub_hdf5_path = [sub_folder,sub_hdf5_file,'.hdf5'];
        
        mask_info = h5info(sub_hdf5_path, '/mask');
        frame_size = mask_info.Dataspace.Size(1:2);
        frame_total = mask_info.Dataspace.Size(3);
        time_start = h5read(sub_hdf5_path,'/time_start'); % start from 0
        time_pos = h5read(sub_hdf5_path,'/vid_time_pos');
        
        normalize_val = 1000;
        
        if frame_total~=length(time_pos)
            sprinf('frame number is not equal to number of time stamps');
        end
        
        cur_mask = h5read(sub_hdf5_path,'/mask');
        
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
            sprintf([num2str(ii),'/',num2str(frame_total),';',num2str(nf),'/',num2str(1)])
            
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
                    curr_img_name = [sub_hdf5_file,'_seg','.tif'];
                    imwrite(cur_seg_img_fl',[sub_folder,curr_img_name]);
                else
                    imwrite(cur_seg_img_fl',[sub_folder,curr_img_name],'WriteMode','append');
                end
                
            end
        end
        
    end
    
end
