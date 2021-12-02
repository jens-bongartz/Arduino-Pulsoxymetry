pkg load instrument-control;
pkg load signal;

disp('Open SerialPort!')

serial_01 = serialport("COM10",115200);  ## COM-nummer anpassen

configureTerminator(serial_01,"lf");
flush(serial_01);   

rot_array = [];
ir_array = [];
t_array = [];
x_index = 0;


cr_lf = [char(13) char(10)];      %% Zeichenkette CR/LF
inBuffer = '';                    %% Buffer serielle Schnittstelle

%% Low Level Grafik
fensterbreite = 200;
fi_1 = figure(1);
clf
sub_1 = subplot(2,1,1);
set(sub_1,"box","on","xlim",[1 fensterbreite],"ylim",[1 1000],"title","IR");
li_1 = line("color","blue");
ma_1 = line("linestyle","none","marker","o");

sub_2 = subplot(2,1,2);
set(sub_2,"box","on","xlim",[1 fensterbreite],"ylim",[1 1000],"title","ROT");
li_2 = line("color","red");
ma_2 = line("linestyle","none","marker","o");

global quit_prg;
quit_prg = 0;

bt1 = uicontrol(fi_1,"style","pushbutton","string","Quit",...
                "callback","bt1_pressed","position",[250,10,100,30]);

function bt1_pressed
  global quit_prg;
  quit_prg = 1;
endfunction

cap1 = uicontrol(fi_1,"style","text","string","BPM:","position",[400,10,120,30]);
cap2 = uicontrol(fi_1,"style","text","string","SpO2:","position",[550,10,200,30]);


disp('Wait for data!')

do
%%until (serial_01.numbytesavailable > 0);
until (serial_01.NumBytesAvailable > 0);

disp('Data available!');

peak_1_x = [];
peak_1_y = [];
peak_2_x = [];
peak_2_y = [];
dyna_rot = 5;
%%dyna_ir = 5;
rot_array = [0 0];
ir_array = [0 0];
t_array = [0 0];
%%x_measure_ir = 1;
x_measure_rot = 1;
t_d_alt = 0;
t_d = 0;
do
   %%bytesavailable = serial_01.numbytesavailable;
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
       
        %% x_index ist eine Indexvariable die immer weiter hochzaehlt 
        x_index++;       
        %% rot_array, ir_array und t_array sind stetig wachsende Vektoren
        
        %% Mittelung ueber die letzten drei Messwerte
        rot_array(end+1)=(rot_array(end-1)+rot_array(end)+rot)/3;
        ir_array(end+1) =(ir_array(end-1) + ir_array(end) +ir)/3;
        t_array(end+1)=t;
        t_d = t_d + t;
        
        %% Punktweise Auswertung der Daten
        %% ===============================
        dx = 2;
        pause = 10;
        rot_threshold = dyna_rot / 10;
        %%ir_threshold = dyna_ir / 10;
        
        if x_index > dx
           delta_rot = (rot_array(x_index-dx) - rot_array(x_index)); %%/ dx
           %%delta_ir  = (ir_array(x_index-dx)  - ir_array(x_index));  %%/ dx
           %% Peakdetektion nur ueber den Rot-Kanal
           if (delta_rot > rot_threshold) && (x_index > x_measure_rot + pause)         
                peak_1_x(end+1) = x_index-dx;
                peak_1_y(end+1) = ir_array(x_index-dx);
                min_1_y = min(ir_array(x_measure_rot:x_index));
                I_IR = peak_1_y(end)
                %%R_ir = (peak_1_y(end)-min_1_y)/min_1_y;
                R_ir = (peak_1_y(end)-min_1_y)/peak_1_y(end);
                
                peak_2_x(end+1) = x_index-dx;
                peak_2_y(end+1) = rot_array(x_index-dx);
                min_2_y = min(rot_array(x_measure_rot:x_index));               
                I_rot = peak_2_y(end)
                %%R_rot = (peak_2_y(end)-min_2_y)/min_2_y;
                R_rot = (peak_2_y(end)-min_2_y)/peak_2_y(end);
                
                R = R_ir / R_rot;
                %%R = R_rot / R_ir;
                %%SpO2 = 104 - 17*R;
                SpO2 = (-45.06*R + 30.354)*R + 94.845
                x_measure_rot = x_index;
                BPM = round(60000 / (t_d - t_d_alt))
                set(cap1,"string",strcat("BPM:_",num2str(BPM)));
                set(cap2,"string",strcat("SpO2:_",num2str(SpO2)));
                t_d_alt = t_d;
           endif
        endif
     endif
          
     if (x_index > fensterbreite)
       %% x-Achse passend umkopieren
       x_axis = x_index-fensterbreite:x_index;
       %% die letzten (fensterbreite=) 80 Werte werden aus rot_array und ir_array in ir_plot und rot_plot umkopiert! 
       ir_plot  = ir_array(x_index-fensterbreite:x_index);
       rot_plot = rot_array(x_index-fensterbreite:x_index);
     
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
     set(ma_1,"xdata",peak_1_x,"ydata",peak_1_y);
     set(li_2,"xdata",x_axis,"ydata",rot_plot);
     set(ma_2,"xdata",peak_2_x,"ydata",peak_2_y);
     drawnow();
     %%dyna_ir  = max(ir_plot) - min(ir_plot);
     dyna_rot = max(rot_plot) - min(rot_plot);     
  endif
  
%%until(kbhit(1) == 'x');    %% Programmende wenn x-Taste gedrückt wird
until(quit_prg);
clear serial_01;

