const gulp = require('gulp');
const concat = require('gulp-concat');
const webpack = require('webpack-stream');
const named = require('vinyl-named');
const uglify = require('gulp-uglify');
const babel = require('gulp-babel');
const cleanCSS = require('gulp-clean-css');
const rename = require('gulp-rename'); 
const fs = require('fs');
const path = require('path');

// Определяем базовую директорию проекта для фронтенда:
// в Docker контейнере используем /app/frontend
const projectRoot = process.env.DOCKER_BUILD ? '/app' : __dirname;
const frontendSrcPath = path.join(projectRoot, 'frontend', 'src');
const baseDir = fs.existsSync(frontendSrcPath) ? path.join(projectRoot, 'frontend') : projectRoot;

// Создание папки dist если её нет
gulp.task('create-dist', (done) => {
  const distPath = path.join(baseDir, 'dist');
  if (!fs.existsSync(distPath)) {
    fs.mkdirSync(distPath, { recursive: true });
  }
  done();
});

// Пути для файлов (абсолютные, чтобы не зависеть от текущей директории)
const paths = {
  styles: {
    src: [
      path.join(baseDir, 'src', 'styles', 'global.css'),
      path.join(baseDir, 'src', 'blocks', '**', '*.css')
    ],
    dest: path.join(baseDir, 'dist')
  },
  scripts: {
    src: [
      path.join(baseDir, 'src', '**', '*.js') // все JS файлы в src и поддиректориях
    ],
    dest: path.join(baseDir, 'dist')
  },
  pages: {
    src: path.join(baseDir, 'src', 'pages', '**', '*.html'),
    dest: path.join(baseDir, 'dist')
  }
};

// Объединение CSS файлов
gulp.task('styles', gulp.series('create-dist', () => {
  return gulp.src(paths.styles.src, { allowEmpty: false })
    .pipe(concat('styles.css'))
    .pipe(gulp.dest(paths.styles.dest))
    .pipe(cleanCSS())
    .pipe(rename({ suffix: '.min' }))
    .pipe(gulp.dest(paths.styles.dest));
}));

// Сборка JavaScript для разных страниц
gulp.task('scripts', gulp.series('create-dist', () => {
  return gulp.src(paths.scripts.src, { allowEmpty: true })
    .pipe(named())
    .pipe(webpack({
      mode: 'production',
      module: {
        rules: [
          {
            test: /\.js$/,
            exclude: /node_modules/,
            use: {
              loader: 'babel-loader',
              options: {
                presets: [
                  ['@babel/preset-env', { 
                    useBuiltIns: 'usage', 
                    corejs: 3 
                  }]
                ]
              }
            }
          }
        ]
      }
    }))
    .pipe(uglify())
    .pipe(gulp.dest(paths.scripts.dest));
}));

// Копирование HTML страниц в dist
gulp.task('pages', gulp.series('create-dist', () => {
  return gulp.src(paths.pages.src, { allowEmpty: true })
    .pipe(gulp.dest(paths.pages.dest));
}));

// Отслеживание изменений
gulp.task('watch', () => {
  gulp.watch(paths.styles.src, gulp.series('styles'));
  gulp.watch([paths.scripts.entry, paths.scripts.blocks], gulp.series('scripts'));
  gulp.watch(paths.pages.src, gulp.series('pages'));
});

// Сборка по умолчанию
gulp.task('default', gulp.parallel('styles', 'scripts', 'pages'));
gulp.task('build', gulp.parallel('styles', 'scripts', 'pages'));
// Запустить Gulp
// gulp / gulp watch(для отслеживания изменений)
