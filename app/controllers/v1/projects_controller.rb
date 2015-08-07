module V1
  class ProjectsController < ApplicationController
    before_action :set_project, only: [:show, :edit, :update, :destroy]
    before_action :authenticate_user_from_token!, only: [:create, :finish, :screenshots, :collaborators]
    before_action :check_registration_open, only: [:create, :finish, :screenshots, :collaborators]

    respond_to :json

    # GET /v1/projects.json
    def index
      edition = if params.has_key?(:edition)
        Edition.published.find_by(id: params[:edition])
      else
        Edition.get_current
      end

      @projects = Project.approved
                         .select("contestants.county, projects.*")
                         .joins(:contestants)
                         .where(:contestants => { :edition => edition })
                         .order("contestants.county")
                         .eager_load(:category)
                         .eager_load(contestants: [:edition, :user])

     @projects.to_a.sort! do |a,b|
       a.contestants[0].county.casecmp(b.contestants[0].county)
     end

    end

    # GET /v1/projects/1.json
    def show
    end

    # POST /v1/projects/:id/finish
    def finish
      contestants = current_user.contestants

      project = Project.joins(:contestants).where(:contestants => { :id => current_user.contestants }).where(id: params[:id]).first

      if project.nil?
        render :json => {}, status: :bad_request
      else
        current_user.increment_registration_step_number!
        project.update_attribute(:finished, true)
        render :json => {}, status: :ok
      end
    end

    # POST /v1/projects/:id/screenshots
    def screenshots
      @project = Project
        .joins(:contestants)
        .where(:contestants => { :id => current_user.contestants })
        .where(id: params[:id])
        .first

      @project.screenshots << params[:screenshots].map do |value|
        Screenshot.new(screenshot: value)
      end

      if @project.screenshots.count >= 3
        current_user.increment_registration_step_number!
      end

      render :show, status: :created
    end

    # POST /v1/project.json
    def create
      category = Category.find_by(name: params[:project][:category])
      current_edition = Edition.get_current
      contestant = current_user.get_current_contestant

      if contestant.nil?
        render json: {error: "No contestant for this edition"},
               status: :unprocessable_entity
        return
      end

      @project = Project.new(
        project_params.merge({
          category: category,
          contestants: [ contestant ]
        })
      )

      if @project.save
        current_user.increment_registration_step_number!
        render :show, status: :created
      else
        render json: @project.errors, status: :unprocessable_entity
      end
    end

    # POST /v1/projects/:id/collaborators
    def collaborators
      project = Project.find(params[:id])
      projects = current_user.get_current_contestant.projects
      contestant = Contestant.find(params[:contestant_id])

      if projects.include?(project) and current_user.registration_step_number == 4
        @colaborator = Colaborator.new({
          project: project,
          contestant: contestant
        })
        if @colaborator.save
          current_user.increment_registration_step_number!
          render :show, status: :created
        else
          render json: @colaborator.errors, status: :unprocessable_entity
        end
      else
        render json: { error: 'unauthorized' }, status: 401
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_project
        @project = Project.find(params[:id])
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def project_params
        params.require(:project).permit(
          :title,
          :description,
          :technical_description,
          :system_requirements,
          :source_url,
          :homepage,
          :category,
          :open_source,
          :closed_source_reason,
          :github_username
        )
      end

      def check_registration_open
        edition = Edition.get_current
        if edition.registration_start_date > Time.now.utc and
           edition.registration_end_date < Time.now.utc
            render json: { error: 'unauthorized' }, status: 401
        end
      end
  end
end
