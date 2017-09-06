module MozillaIAM
  class MozillaIAM::Admin::GroupMappingsController < ::Admin::AdminController

    def index
      mappings = GroupMapping.all
      render_serialized(mappings, GroupMappingSerializer)
    end

    def new
    end

    def create
      mapping = GroupMapping.new(group_mappings_params)
      mapping.authoritative = false if params[:authoritative].nil?
      mapping.group = Group.find_by(name: params[:group_name])
      mapping.save!
      render json: success_json
    end

    def show
      params.require(:id)
      mapping = GroupMapping.find(params[:id])
      render_serialized(mapping, GroupMappingSerializer)
    end

    def update
      params.require(:id)
      mapping = GroupMapping.find(params[:id])
      mapping.update_attributes!(group_mappings_params)
      render json: success_json
    end

    def destroy
      params.require(:id)
      mapping = GroupMapping.find(params[:id])
      mapping.destroy
      render json: success_json
    end

    def group_mappings_params
      params.permit(
        :id,
        :iam_group_name,
        :authoritative
      )
    end

  end
end
