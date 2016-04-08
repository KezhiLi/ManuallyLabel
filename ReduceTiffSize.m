% script run to reduce the tiff size from normal uint8 to indexed uint8
% 
% change the 'path_to' and 'path_from' accordly to generate the new tiff
% files with the same name but smaller size. Normally based on experience
% and file size can be reduced from 0.45M from 18M.
% 
% 
% 
% 
% 
% 

folder = 'tif_large_file_backup\';
path_to = 'N:\Kezhi\DataSet\AllFiles\OutSource_files\All_Label\';
path_from = [path_to,folder];

root_folder = genpath([path_to,'.']);

file=dir([path_from,'*.tif']);
num_file = size(file,1);

for nf = 1:num_file;
    disp(nf/num_file)
    if file(nf).bytes>5e6
        
        tif_file = file(nf).name(1:end-4);
        tif_path = [path_from,tif_file,'.tif'];
        tiff_info = imfinfo(tif_path); 
        
        fileRead=[path_from,tif_file,'.tif'];
        fileWrite=[path_to,tif_file,'.tif'];
        for i=1:size(tiff_info, 1)
            data=imread(fileRead,i);
            imshow(data);
            frame=getframe;
            im=frame2im(frame);
            [I,map]=rgb2ind(im,256);
            I=I(1:end-1,1:end-1);
            if i==1
                imwrite(I,map,fileWrite,'tif');
            else
                imwrite(I,map,fileWrite,'tif','WriteMode','append');
            end
        end

    end
end












