%% ============ re_厚度.txt 数据插值图（真实大地坐标轴） ============
% 读取 GmLine v3.0(Contour) 格式的厚度散点，插值成规则网格后绘制。
% 坐标轴使用真实大地坐标（km），不从 0 开始。
clear; clc; close all;

[X, Y, Z] = read_thickness('re_厚度.txt');

% 去掉 Z=0 的无效点，去除重复坐标
keep = Z ~= 0;
X = X(keep); Y = Y(keep); Z = Z(keep);
[~, ia] = unique([X Y], 'rows', 'stable');
X = X(ia); Y = Y(ia); Z = Z(ia);

fprintf('读取散点个数 : %d\n', numel(Z));
fprintf('厚度范围     : %.1f ~ %.1f m\n', min(Z), max(Z));
fprintf('X 范围       : %.3f ~ %.3f m\n', min(X), max(X));
fprintf('Y 范围       : %.3f ~ %.3f m\n', min(Y), max(Y));

% 规则网格（1000 m 间距），坐标保持真实大地坐标（不减去最小值）
dx = 1000; dy = 1000;
xg = min(X):dx:max(X);
yg = min(Y):dy:max(Y);
[Xg, Yg] = meshgrid(xg, yg);

% 插值：坐标中心化保证数值稳定（~1e7 量级）
mx = mean(X); my = mean(Y);
F = scatteredInterpolant(X-mx, Y-my, Z, 'natural', 'none');
Zg = F(Xg-mx, Yg-my);

% 绘图：坐标轴用真实大地坐标（km），X/Y 轴从真实起点开始
figure('Color','w');
contourf(Xg/1000, Yg/1000, Zg, 30, 'LineStyle','none');
colorbar; colormap(gca, parula);
axis equal tight;
xlabel('X / km'); ylabel('Y / km');
title('寒武系烃源岩厚度插值图');

% 叠加原始等值线散点，检查插值是否贴合原始数据
hold on;
plot(X/1000, Y/1000, 'k.', 'MarkerSize', 3);
hold off;

%% ================= 局部函数 =================
function [X, Y, Z] = read_thickness(filename)
% 读取 GmLine v3.0(Contour) 格式：块头为“点数 Z值”，随后是“X Y -1”坐标行。
% 块头 Z 值为空时沿用上一块的 Z 值。
fid = fopen(filename, 'r', 'n', 'UTF-8');
if fid < 0, error('无法打开文件: %s', filename); end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fgetl(fid);  % 跳过首行 GmLine v3.0(Contour)

X = zeros(0,1); Y = zeros(0,1); Z = zeros(0,1);
currentZ = NaN;
while ~feof(fid)
    headerLine = fgetl(fid);
    if ~ischar(headerLine) || isempty(strtrim(headerLine)), continue; end
    header = strsplit(headerLine, '\t', 'CollapseDelimiters', false);

    pointCount = str2double(strtrim(header{1}));
    if isnan(pointCount) || pointCount < 0 || pointCount ~= floor(pointCount)
        continue;
    end

    if numel(header) >= 2 && ~isempty(strtrim(header{2}))
        newZ = str2double(strtrim(header{2}));
        if ~isnan(newZ), currentZ = newZ; end
    end

    for p = 1:pointCount
        if feof(fid), break; end
        coordLine = fgetl(fid);
        coord = strsplit(coordLine, '\t', 'CollapseDelimiters', false);
        if numel(coord) < 2, continue; end
        xv = str2double(strtrim(coord{1}));
        yv = str2double(strtrim(coord{2}));
        if ~isnan(xv) && ~isnan(yv) && ~isnan(currentZ)
            X(end+1,1) = xv; Y(end+1,1) = yv; Z(end+1,1) = currentZ;
        end
    end
end
end
