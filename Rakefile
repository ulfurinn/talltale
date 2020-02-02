namespace :dev do
  desc 'start the backend server'
  task :back do
    sh 'modd'
  end
  task backend: :back

  desc 'start the frontend server'
  task :front do
    sh 'npm start'
  end
  task frontend: :front
end

namespace :docker do
  desc 'build a local docker image'
  task :build do
    sh 'docker build -t talltale .'
  end

  desc 'run the local docker image'
  task :run do
    images = `docker images talltale --format '{{.ID}}'`.chomp
    if images.empty?
      Rake::Task['docker:build'].invoke
    end
    sh 'docker run --rm -p 8080:8080 talltale'
  end
end
