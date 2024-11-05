%% init
clear;clc;
% subject&study info
prompt = {'Subject''s ID:', 'Start Run:'};
subject = input(prompt{1});
block = input(prompt{2});
% debug
debug = 0;
AssertOpenGL;
commandwindow;
if debug
    ListenChar(0);
    ShowCursor();
    PsychDebugWindowConfiguration;
else
    ListenChar(2);
    HideCursor();
end
% global veriable  
global x
% screen settings
x.ins_color = [255 255 255];
x.bg_color = [122 122 122];
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(2);
x.screenNumber = max(Screen('Screens'));
[x.window, x.windowRect] = Screen('OpenWindow', x.screenNumber, x.bg_color);
[x.x_center, x.y_center] = RectCenter(x.windowRect);
Screen('TextColor', x.window, 30); 
Screen('Preference','TextEncodingLocale','UTF-8');
% keyboard defination
KbName('UnifyKeyNames');
continue_key = KbName('space');
quit_key = KbName('ESCAPE');
reaction_key = KbName('space');
% port setting
port_address = hex2dec('037F');
    %config_io;
    % outp(port_address, 0);
%{
Stimulus Markers
    
Choice & SolderNumber Markers
    ChoiceStart=soldier_num Launch=100 other_key=200 Non-response=199
Others
    RunStart=88 Rest=66
%}
% experiment settings
n_block = 5;
n_trial = 225;
trial_duration = 1;
% create result data
mkdir(sprintf('result/oddball/sub_%d', subject));
result = table();
result = addvars(result, string.empty(), 'NewVariableNames', "stimulus");
%% degree
pw=x.windowRect(1);  %screen size pixel
ph=x.windowRect(2);
viewDist=80; % 眼睛距离屏幕的距离，文中提到大概50
ScrWidth=26; % 屏幕宽
%now calculate how many pixels correspond to 1 deg visual angle
widthDeg = round(2*180*atan(ScrWidth/(2*viewDist))/pi); % visual angle deg of the ScrWidth
deg2pix  = round(pw/widthDeg);
%% Practice Block
if block == 1
    % introduction
    IntroImage = imread('stimuli_oddball/introduction.png');
    PracticeImage = imread('stimuli_oddball/practice.png');
    ShowPicWaitKey(IntroImage);
    ShowPicWaitKey(PracticeImage);
    % 15 practice trials(3 target,3 probes,9 distractors)
    load("stimuli_oddball/practice/prac_order.mat")
    for i = 1:2
        prac_trial = prac_order(i);
        switch prac_trial
            case {1,2,3}
                IntroStimPic = imread('stimuli_oddball/practice/prac_target.png');
            case {4,5,6}
                IntroStimPic = imread(sprintf('stimuli_oddball/practice/probe_%d.png',prac_trial-3));
            case {7,8,9,10,11,12,13,14,15}
                IntroStimPic = imread(sprintf('stimuli_oddball/practice/prac_distractors_%d.png',prac_trial-6));
        end
        % Practice Screen
        FlipFix();
        ShowPic(IntroStimPic);   
        t_start = Screen('Flip', x.window);
        while KbCheck(), end           
        while GetSecs - t_start < trial_duration
            [keyIsDown, t_end, keyCode] = KbCheck();      
            if keyIsDown
                    if keyCode(quit_key)
                        ListenChar(0);
                        ShowCursor();
                        Screen('CloseAll');
                        return; 
                    elseif ~keyCode(reaction_key)
                        fb=0;%false alarm
                        break;
                    elseif keyCode(reaction_key)
                        if ismember(prac_trial,4:1:15)
                            fb=0;%false alarm
                            break;
                        else
                            fb=1;%correct
                            break;
                        end
                    end
            end
        end
            if  GetSecs - t_start >= trial_duration
                if ismember(prac_trial,4:1:15)
                    fb=1;%correct missing
                else
                    fb=0;%missing
                end
            end        
            feedback(fb);
    end
end
%% formal exp
% introduction
expintro_image = imread('stimuli_oddball/exp.png');
ShowPicWaitKey(expintro_image);
% load(sprintf("order/%d.mat",subject));
% generate stimulation order, probe1-child, probe2-pregnant, probe3-drunk,
% probe4-criminal, probe5-civilian
exp_text = oddball_generate; 
BreakPic = imread('stimuli_oddball/break.png');
for i = block:n_block
%     outp(port_address, 88);
%     WaitSecs(0.004);
%     outp(port_address, 0);
    for j = 1:n_trial
        order = exp_text(i,j);
% order: ABC,A:stim_type; B:probe_num;C:soldier_num
% stim_type: (1-child,2-pregnant,3-drug,4-criminal,5-civilian,6-none)
% count soldier_num and identity
        stim_type = floor(order/100);
        soldier_num = mod(order,10);
        probe_num = (order-soldier_num-stim_type*100)/10;
%         stim_marker = stim_type;
%         sold_marker = soldier_num;
        % stim picture
        switch stim_type
            case 1
                id = 'child';
            case 2
                id = 'pregnant';
            case 3
                id = 'drug';
            case 4
                id = 'criminal';
            case 5 
                id = 'civilian';
            case 6
                id = 0;
        end
        t = FlipFix();
        warning off
        result.stimulus(2*j-1) = "fixation";
        result.response(2*j-1) = 99;
        result.rt(2*j-1) = t;
        warning on
%         outp(port_address, sold_marker);%255(sold_num,stim_num,type)
%         WaitSecs(0.004);
%         outp(port_address, 0);
        if id==0 
            StimPic = imread(sprintf('stimuli_oddball/exp/target_distractors/soldier_%d.png',soldier_num));
            ShowPic(StimPic);
        else
            StimPic = imread(sprintf(['stimuli_oddball/exp/probes/',id,'.png']));
            ShowPic(StimPic);
            Screen('TextSize',x.window,40);
            DrawFormattedText(x.window, double(num2str(soldier_num)), x.x_center+30, 700, [255, 255, 255]);
            DrawFormattedText(x.window, double(num2str(probe_num)), x.x_center+30, 800, [255, 255, 255]);
        end
        t_start = Screen('Flip', x.window);
        warning off
        while KbCheck(), end
        while GetSecs - t_start < trial_duration
            [keyIsDown, t_end, keyCode] = KbCheck();
            if keyIsDown
                    if keyCode(quit_key)
                        ListenChar(0);
                        ShowCursor();
                        Screen('CloseAll');
                        return; 
                    elseif ~keyCode(reaction_key)
% outp(port_address, 200);
% WaitSecs(0.004);
% outp(port_address, 0);
                        result.rt(2*j) = GetSecs - t_start;
                        response=0;
                        break;    %false alarm
                    elseif keyCode(reaction_key)
                        result.rt(2*j) = GetSecs - t_start;
                        response=1;
% outp(port_address, 100);
% WaitSecs(0.004);
% outp(port_address, 0);
                        break;
                    end
            end
        end
        if  GetSecs - t_start >= trial_duration
% outp(port_address, 199);
% WaitSecs(0.004);
% outp(port_address, 0);
                response = 99;
                result.rt(2*j) = trial_duration;
        end      

        result.stimulus(2*j) = order;
        result.response(2*j) = response; % 0-wrong_reaction; 1-reaction; 99-no_reaction
        warning on
    end
    % calculate accuracy
    right = 0;
    for n = 1:n_trial
        ABC = result.stimulus(2*n);
        R = result.response(2*n);
        A = floor(ABC/100); % stim_type
        B = mod(ABC,10); % solder_num
        C = (ABC-B-C*100)/10; % probe_num
        if ABC==600 && R==1
            right = right+1;
        elseif ABC~=600 && R==99
            right = right+1;
        end
    end
    result.accuracy(i) = right/n_trial;
    % save data
    writetable(result, sprintf('result/oddball/sub_%d/block_%d.csv', subject, i));
    % rest
    if i < n_block
%         outp(port_address, 66);
%         outp(port_address, 0);
%remind of accuracy
        acc = result.accuracy(i);
        if acc<0.8
            over_error = imread('stimuli_oddball/over_error.png');
            ShowPicWaitKey(over_error);
        end
        ShowPicWaitKey(BreakPic);

    end
end
%% finish
finish_image = imread('stimuli_oddball/finish.png');
ShowPicWaitKey(finish_image);
Screen('CloseAll');
ListenChar(0);
ShowCursor();
final_data = readtable(sprintf('result/oddball/sub_%d/block_1.csv', subject));
for i = 2:5
    final_data = vertcat(final_data, readtable(sprintf('result/oddball/sub_%d/block_%d.csv', subject, i)));
end
writetable(final_data, sprintf('result/oddball/sub_%d/result.csv', subject));

%% function
% Show picture untill key is press down
function ShowPicWaitKey(image)
global x
texture = Screen('MakeTexture', x.window, image);
Screen('DrawTexture', x.window, texture);
Screen('Flip', x.window);
while KbCheck(), end
KbStrokeWait;
Screen('Flip', x.window);
end

%% Draw fixation
function fixation_duration = FlipFix(t)
global x %#ok<*GVMIS> 
if nargin < 1
	fixation_duration = 0.5;
else 
    fixation_duration = 0.5-t;
end 

fixation = '+';
fixation_size = 100;
Screen('TextSize', x.window, fixation_size);
rect = Screen('TextBounds', x.window, fixation);
width = rect(3) - rect(1);
% highth = rect(2) - rect(1);
fix_x = (2*x.x_center-width)/2;
% fix_y = (2*x.y_center-highth)/2;
DrawFormattedText(x.window, fixation, fix_x, x.y_center+50, x.ins_color);
% Screen('DrawText', x.window, fixation, x.x_center-0.5*fixation_size, x.y_center-0.5*fixation_size, x.ins_color);
Screen('Flip', x.window);
WaitSecs(fixation_duration);
end

%% Draw picture on screen
function DrawPic(image,y)
global x
texture = Screen('MakeTexture', x.window, image);
width = 0.20 * x.windowRect(3);
height = width*(5/4);
rect = [x.x_center-0.5*width, y-0.5*height, x.x_center+0.5*width, y+0.5*height];
Screen('DrawTexture', x.window, texture, [], rect);
end

%% Show picture untill key is press down
function ShowPicWaitSec(image,t)
global x
texture = Screen('MakeTexture', x.window, image);
Screen('DrawTexture', x.window, texture);
Screen('Flip', x.window);
WaitSecs(t);
end

function ShowPic(image)
global x
texture = Screen('MakeTexture', x.window, image);
Screen('DrawTexture', x.window, texture);
% Screen('Flip', x.window);
end 

%% give feedback in practice
function feedback(tf)
global x
if tf==0
ShowPic(imread('stimuli_oddball\practice\red.png')); 
Screen('Flip', x.window);
WaitSecs(1);
else
ShowPic(imread('stimuli_oddball\practice\green.png'));  %correct
Screen('Flip', x.window);
WaitSecs(1);
end
end