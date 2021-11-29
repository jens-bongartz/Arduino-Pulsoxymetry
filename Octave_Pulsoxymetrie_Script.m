pkg load instrument-control;
pkg load signal;

clear all;
disp('Open SerialPort!')

serial_01 = serialport("COM9",115200);  ## COM-nummer anpassen

configureTerminator(serial_01,"lf");
flush(serial_01);   

rot_array = [];
ir_array = [];
t_array = [];
x_index = 0;

cr_lf = [char(13) char(10)];      %% Zeichenkette CR/LF
inBuffer = '';                    %% Buffer serielle Schnittstelle
disp('Wait for data!')

%% Low Level Grafik
fensterbreite = 80;
fi_1 = figure(1);
clf
sub_1 = subplot(2,1,1);
set(sub_1,"box","on","xlim",[1 fensterbreite],"ylim",[1 1000],"title","IR");
li_1 = line("color","blue");
sub_2 = subplot(2,1,2);
set(sub_2,"box","on","xlim",[1 fensterbreite],"ylim",[1 1000],"title","ROT");
li_2 = line("color","red");

global quit_prg;
quit_prg = 0;

bt1 = uicontrol(fi_1,"style","pushbutton","string","Quit",...
                "callback","bt1_pressed","position",[250,10,100,30]);

function bt1_pressed
  global quit_prg;
  quit_prg = 1;
endfunction

do
%%until (serial_01.numbytesavailable > 0);
until (serial_01.NumBytesAvailable > 0);


do
%%   bytesavailable = serial_01.numbytesavailable;
   bytesavailable = serial_01.NumBytesAvailable;
   
   if (bytesavailable > 0)
     %% Zeilenende (println) ist ASCII Kombination 13 10
     %% char(13) = CR char(10) = LF
     inSerialPort = char(read(serial_01,bytesavailable)); %% Daten werden vom SerialPort gelesen
     inBuffer     = [inBuffer inSerialPort];              %% und an den inBuffer angehängt
     posCRLF      = rindex(inBuffer, cr_lf);              %% Test auf CR/LF im inBuffer 
     if (posCRLF > 0)          
        inChar   = inBuffer(1:posCRLF-1);
        inChar   = inChar(~isspace(inChar));              %% Leerzeichen aus inChar entfernen
        inBuffer = inBuffer(posCRLF+2:end);        
        inNumbers = strsplit(inChar,{',','ir:','rot:', 't:'});
        count = length(inNumbers);                                    %% erste Element bei strsplit ist ´hier immer
        %% Es wird davon ausgegangen, dass der Arduino
        %% zuerst ROT und dann IR uebertraegt      
        rot = str2num(inNumbers{2});                   %% ein Leerstring
        ir  = str2num(inNumbers{3});
        t   = str2num(inNumbers{4});
       
        %% rot_array, ir_array und t_array sind stetig wachsende Vektoren
        rot_array(end+1)=rot;
        ir_array(end+1)=ir;
        t_array(end+1)=t;
        %% x_index ist eine Indexvariable die immer weiter hochzaehlt 
        x_index++;       
     endif
          
     if (x_index > fensterbreite)
       x_axis = x_index-fensterbreite:x_index;
       %% die letzten (fensterbreite=) 80 Werte werden aus rot_array und ir_array in ir_plot und rot_plot umkopiert! 
       ir_plot  = ir_array(x_index-fensterbreite:x_index);
       rot_plot = rot_array(x_index-fensterbreite:x_index);
       
       %%[rot_peak, rot_loc] = findpeaks(rot_plot);
       %%[ir_peak, ir_loc] = findpeaks(ir_plot);
       
       set(sub_1, "xlim", [x_index-fensterbreite x_index],"ylim",[min(ir_plot)-10 max(ir_plot)+10]);
       set(sub_2, "xlim", [x_index-fensterbreite x_index],"ylim",[min(rot_plot)-10 max(rot_plot)+10]);
     else
       x_axis = 1:x_index;
       ir_plot = ir_array;
       rot_plot = rot_array;
       set(sub_1, "ylim",[min(ir_plot)-10 max(ir_plot)+10]);
       set(sub_2, "ylim",[min(rot_plot)-10 max(rot_plot)+10]);
       
     endif     
     set(li_1,"xdata",x_axis,"ydata",ir_plot);
     set(li_2,"xdata",x_axis,"ydata",rot_plot);
     drawnow();
  endif
     

%%until(kbhit(1) == 'x');    %% Programmende wenn x-Taste gedrückt wird
until(quit_prg);

clear serial_01;